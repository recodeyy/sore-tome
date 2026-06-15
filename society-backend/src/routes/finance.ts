import { Router, Request, Response } from "express";
import { FinanceService } from "../services/finance/FinanceService";
import { ExpenseService } from "../services/finance/ExpenseService";
import { RazorpayWebhookService } from "../services/payment/RazorpayWebhookService";
import { FinanceReportService } from "../services/finance/FinanceReportService";
import { ReconciliationService } from "../services/finance/ReconciliationService";
import { validate } from "../middleware/validate";
import { CreateInvoiceSchema, RecordPaymentSchema, CreateExpenseSchema, DecideExpenseSchema } from "../shared/schemas";
import { logger } from "../shared/Logger";

// @ts-ignore — JS middleware
import { authMiddleware, canManageFunds } from "../../middleware/auth";
import { tenantMiddleware } from "../../middleware/tenantMiddleware";

const router = Router();

const societyOf = (req: Request) => (req as any).societyId as string;

// GET /finance/invoices — list invoices for the society
router.get("/invoices", authMiddleware, tenantMiddleware, async (req: Request, res: Response) => {
  try {
    const status = typeof req.query.status === "string" ? req.query.status : undefined;
    const limit = req.query.limit ? Number(req.query.limit) : undefined;
    const invoices = await FinanceService.listInvoices(societyOf(req), { status, limit });
    res.json({ invoices });
  } catch (err: any) {
    logger.error({ error: err.message }, "List invoices failed");
    res.status(500).json({ error: "Failed to list invoices" });
  }
});

// GET /finance/invoices/:id — one invoice with its lines
router.get("/invoices/:id", authMiddleware, tenantMiddleware, async (req: Request, res: Response) => {
  try {
    const invoice = await FinanceService.getInvoice(societyOf(req), req.params.id);
    if (!invoice) return res.status(404).json({ error: "Invoice not found" });
    res.json({ invoice });
  } catch (err: any) {
    logger.error({ error: err.message }, "Get invoice failed");
    res.status(500).json({ error: "Failed to get invoice" });
  }
});

// POST /finance/invoices — create a draft invoice
router.post("/invoices", authMiddleware, tenantMiddleware, canManageFunds, validate(CreateInvoiceSchema), async (req: Request, res: Response) => {
  try {
    const invoice = await FinanceService.createInvoice(societyOf(req), req.body, (req as any).user?.uid);
    res.status(201).json({ invoice });
  } catch (err: any) {
    if (err.code === "23505") return res.status(409).json({ error: "Invoice number already exists" });
    logger.error({ error: err.message }, "Create invoice failed");
    res.status(500).json({ error: "Failed to create invoice" });
  }
});

// POST /finance/invoices/:id/publish — publish draft, post to ledger
router.post("/invoices/:id/publish", authMiddleware, tenantMiddleware, canManageFunds, async (req: Request, res: Response) => {
  try {
    const invoice = await FinanceService.publishInvoice(societyOf(req), req.params.id);
    res.json({ invoice });
  } catch (err: any) {
    if (err.code === "NOT_FOUND") return res.status(404).json({ error: "Invoice not found" });
    if (err.code === "INVALID_STATE") return res.status(409).json({ error: err.message });
    logger.error({ error: err.message }, "Publish invoice failed");
    res.status(500).json({ error: "Failed to publish invoice" });
  }
});

// POST /finance/invoices/:id/late-fee — apply a configurable late fee (idempotent)
router.post("/invoices/:id/late-fee", authMiddleware, tenantMiddleware, canManageFunds, async (req: Request, res: Response) => {
  try {
    const result = await FinanceService.applyLateFee(societyOf(req), req.params.id, req.body);
    res.json(result);
  } catch (err: any) {
    if (err.code === "NOT_FOUND") return res.status(404).json({ error: "Invoice not found" });
    if (err.code === "INVALID_STATE") return res.status(409).json({ error: err.message });
    logger.error({ error: err.message }, "Apply late fee failed");
    res.status(500).json({ error: "Failed to apply late fee" });
  }
});

// POST /finance/invoices/:id/late-fee/waive — waive an applied late fee
router.post("/invoices/:id/late-fee/waive", authMiddleware, tenantMiddleware, canManageFunds, async (req: Request, res: Response) => {
  try {
    const result = await FinanceService.waiveLateFee(societyOf(req), req.params.id, { reason: req.body.reason, waivedBy: (req as any).user?.uid });
    res.json(result);
  } catch (err: any) {
    if (err.code === "NOT_FOUND") return res.status(404).json({ error: "Invoice not found" });
    logger.error({ error: err.message }, "Waive late fee failed");
    res.status(500).json({ error: "Failed to waive late fee" });
  }
});

// POST /finance/credit-notes — issue an immutable credit note against an invoice
router.post("/credit-notes", authMiddleware, tenantMiddleware, canManageFunds, async (req: Request, res: Response) => {
  try {
    const cn = await FinanceService.createCreditNote(societyOf(req), { ...req.body, createdBy: (req as any).user?.uid });
    res.status(201).json({ creditNote: cn });
  } catch (err: any) {
    if (err.code === "NOT_FOUND") return res.status(404).json({ error: "Invoice not found" });
    if (err.code === "INVALID_STATE" || err.code === "VALIDATION") return res.status(409).json({ error: err.message });
    logger.error({ error: err.message }, "Create credit note failed");
    res.status(500).json({ error: "Failed to create credit note" });
  }
});

// POST /finance/recurring-billing — generate the next period's billing run (idempotent)
router.post("/recurring-billing", authMiddleware, tenantMiddleware, canManageFunds, async (req: Request, res: Response) => {
  try {
    const result = await FinanceService.runRecurringBilling(societyOf(req), req.body, (req as any).user?.uid);
    res.status(result.duplicate ? 200 : 201).json(result);
  } catch (err: any) {
    if (err.code === "23505") return res.status(409).json({ error: "Invoice number already exists" });
    logger.error({ error: err.message }, "Recurring billing failed");
    res.status(500).json({ error: "Failed to run recurring billing" });
  }
});

// POST /finance/receipts/:id/void — void (and optionally reissue) a receipt
router.post("/receipts/:id/void", authMiddleware, tenantMiddleware, canManageFunds, async (req: Request, res: Response) => {
  try {
    const result = await FinanceService.voidReceipt(societyOf(req), req.params.id, { reason: req.body.reason, reissue: req.body.reissue, voidedBy: (req as any).user?.uid });
    res.json(result);
  } catch (err: any) {
    if (err.code === "NOT_FOUND") return res.status(404).json({ error: "Receipt not found" });
    if (err.code === "INVALID_STATE") return res.status(409).json({ error: err.message });
    logger.error({ error: err.message }, "Void receipt failed");
    res.status(500).json({ error: "Failed to void receipt" });
  }
});

// POST /finance/payments — record a payment (idempotent)
router.post("/payments", authMiddleware, tenantMiddleware, canManageFunds, validate(RecordPaymentSchema), async (req: Request, res: Response) => {
  try {
    const { payment, duplicate } = await FinanceService.recordPayment(societyOf(req), req.body);
    res.status(duplicate ? 200 : 201).json({ payment, duplicate });
  } catch (err: any) {
    if (err.code === "NOT_FOUND") return res.status(404).json({ error: "Invoice not found" });
    logger.error({ error: err.message }, "Record payment failed");
    res.status(500).json({ error: "Failed to record payment" });
  }
});

// GET /finance/expenses — list expenses
router.get("/expenses", authMiddleware, tenantMiddleware, async (req: Request, res: Response) => {
  try {
    const status = typeof req.query.status === "string" ? req.query.status : undefined;
    const limit = req.query.limit ? Number(req.query.limit) : undefined;
    const expenses = await ExpenseService.listExpenses(societyOf(req), { status, limit });
    res.json({ expenses });
  } catch (err: any) {
    logger.error({ error: err.message }, "List expenses failed");
    res.status(500).json({ error: "Failed to list expenses" });
  }
});

// POST /finance/expenses — create an expense (pending approval)
router.post("/expenses", authMiddleware, tenantMiddleware, canManageFunds, validate(CreateExpenseSchema), async (req: Request, res: Response) => {
  try {
    const expense = await ExpenseService.createExpense(societyOf(req), req.body, (req as any).user?.uid);
    res.status(201).json({ expense });
  } catch (err: any) {
    logger.error({ error: err.message }, "Create expense failed");
    res.status(500).json({ error: "Failed to create expense" });
  }
});

// POST /finance/expenses/:id/decision — approve/reject (maker-checker)
router.post("/expenses/:id/decision", authMiddleware, tenantMiddleware, canManageFunds, validate(DecideExpenseSchema), async (req: Request, res: Response) => {
  try {
    const expense = await ExpenseService.decide(societyOf(req), req.params.id, (req as any).user?.uid, req.body.decision, req.body.comment);
    res.json({ expense });
  } catch (err: any) {
    if (err.code === "NOT_FOUND") return res.status(404).json({ error: "Expense not found" });
    if (err.code === "INVALID_STATE") return res.status(409).json({ error: err.message });
    if (err.code === "MAKER_CHECKER") return res.status(403).json({ error: err.message });
    logger.error({ error: err.message }, "Decide expense failed");
    res.status(500).json({ error: "Failed to decide expense" });
  }
});

// GET /finance/reports/summary — collections, dues, expenses for the society
router.get("/reports/summary", authMiddleware, tenantMiddleware, async (req: Request, res: Response) => {
  try {
    res.json(await FinanceReportService.summary(societyOf(req)));
  } catch (err: any) {
    logger.error({ error: err.message }, "Finance summary failed");
    res.status(500).json({ error: "Failed to build summary" });
  }
});

// GET /finance/reports/trial-balance — per-account debit/credit totals
router.get("/reports/trial-balance", authMiddleware, tenantMiddleware, async (req: Request, res: Response) => {
  try {
    res.json(await FinanceReportService.trialBalance(societyOf(req)));
  } catch (err: any) {
    logger.error({ error: err.message }, "Trial balance failed");
    res.status(500).json({ error: "Failed to build trial balance" });
  }
});

// GET /finance/reports/dues — outstanding invoices with ageing buckets
router.get("/reports/dues", authMiddleware, tenantMiddleware, async (req: Request, res: Response) => {
  try {
    res.json(await FinanceReportService.dues(societyOf(req)));
  } catch (err: any) {
    logger.error({ error: err.message }, "Dues report failed");
    res.status(500).json({ error: "Failed to build dues report" });
  }
});

// POST /finance/webhook/razorpay — public; verified by raw-body HMAC signature.
// Path contains "/webhook" so server.js captures req.rawBody for signature checking.
router.post("/webhook/razorpay", async (req: Request, res: Response) => {
  const rawBody = (req as any).rawBody || JSON.stringify(req.body);
  const signature = req.headers["x-razorpay-signature"] as string | undefined;
  const eventId = req.headers["x-razorpay-event-id"] as string | undefined;
  try {
    const result = await RazorpayWebhookService.handle(rawBody, signature, eventId);
    // Always 200 on a valid signature so Razorpay stops retrying.
    res.status(200).json({ ok: true, ...result });
  } catch (err: any) {
    if (err.code === "INVALID_SIGNATURE") return res.status(400).json({ error: "Invalid signature" });
    logger.error({ error: err.message }, "Razorpay webhook handling failed");
    res.status(500).json({ error: "Webhook processing failed" });
  }
});

// ── Bank reconciliation (capability 40) ──────────────────────────────────────
function reconErr(res: Response, err: any, log: string) {
  if (err.code === "NOT_FOUND") return res.status(404).json({ success: false, error: { code: err.code, message: err.message } });
  if (err.code === "VALIDATION") return res.status(400).json({ success: false, error: { code: err.code, message: err.message } });
  logger.error({ error: err.message }, log);
  return res.status(500).json({ success: false, error: { code: err.code || "INTERNAL", message: err.message } });
}

// POST /finance/reconciliation/accounts — register a bank account
router.post("/reconciliation/accounts", authMiddleware, tenantMiddleware, canManageFunds, async (req: Request, res: Response) => {
  try {
    const data = await ReconciliationService.createAccount(societyOf(req), req.body);
    res.status(201).json({ success: true, data });
  } catch (err: any) {
    reconErr(res, err, "Create bank account failed");
  }
});

// POST /finance/reconciliation/imports — import a statement with lines
router.post("/reconciliation/imports", authMiddleware, tenantMiddleware, canManageFunds, async (req: Request, res: Response) => {
  try {
    const data = await ReconciliationService.importStatement(societyOf(req), req.body);
    res.status(201).json({ success: true, data });
  } catch (err: any) {
    reconErr(res, err, "Import statement failed");
  }
});

// POST /finance/reconciliation/imports/:id/auto-match — auto-match lines to payments
router.post("/reconciliation/imports/:id/auto-match", authMiddleware, tenantMiddleware, canManageFunds, async (req: Request, res: Response) => {
  try {
    const data = await ReconciliationService.autoMatch(societyOf(req), req.params.id);
    res.json({ success: true, data });
  } catch (err: any) {
    reconErr(res, err, "Auto-match failed");
  }
});

// POST /finance/reconciliation/lines/:id/match — manually match a line to a payment
router.post("/reconciliation/lines/:id/match", authMiddleware, tenantMiddleware, canManageFunds, async (req: Request, res: Response) => {
  try {
    const data = await ReconciliationService.manualMatch(societyOf(req), req.params.id, req.body.paymentId);
    res.json({ success: true, data });
  } catch (err: any) {
    reconErr(res, err, "Manual match failed");
  }
});

// GET /finance/reconciliation/imports/:id/summary — reconciliation summary
router.get("/reconciliation/imports/:id/summary", authMiddleware, tenantMiddleware, async (req: Request, res: Response) => {
  try {
    const data = await ReconciliationService.summary(societyOf(req), req.params.id);
    res.json({ success: true, data });
  } catch (err: any) {
    reconErr(res, err, "Reconciliation summary failed");
  }
});

export default router;
