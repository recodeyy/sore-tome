const express = require("express");
const router = express.Router();
const { getDb, getAdmin } = require("../config/firebase");
const { authMiddleware, canManageFunds } = require("../middleware/auth");
const { tenantMiddleware } = require("../middleware/tenantMiddleware");
const { AuditLogService } = require("../src/services/AuditLogService");
const { logger } = require("../src/shared/Logger");
const { validate } = require("../src/middleware/validate");
const { CreateTransactionSchema } = require("../src/shared/schemas");

// GET /funds — current month summary
router.get("/", authMiddleware, tenantMiddleware, async (req, res) => {
  const ip = req.ip || req.headers["x-forwarded-for"] || "unknown";
  try {
    const db = getDb();
    const snap = await db.collection("funds")
      .where("society_id", "==", req.societyId)
      .limit(100)
      .get();

    const funds = snap.docs.map((doc) => {
      const data = doc.data();
      return {
        id: doc.id,
        ...data,
        createdAt: data.createdAt ? data.createdAt.toDate().toISOString() : null,
      };
    })
    .sort((a, b) => new Date(b.createdAt || 0).getTime() - new Date(a.createdAt || 0).getTime())
    .slice(0, 12);
    res.json({ funds });
  } catch (err) {
    logger.error({ ip, error: err.message }, "Error fetching funds");
    res.status(500).json({ error: "Internal server error" });
  }
});

// GET /funds/transactions — recent transactions ledger
router.get("/transactions", authMiddleware, tenantMiddleware, async (req, res) => {
  const ip = req.ip || req.headers["x-forwarded-for"] || "unknown";
  try {
    const { cursor, limit = 30 } = req.query;
    const db = getDb();
    
    // Fetch with equality filter only (no composite index needed), sort and
    // paginate in memory using the cursor id
    const snap = await db
      .collection("transactions")
      .where("society_id", "==", req.societyId)
      .limit(500)
      .get();

    const all = snap.docs.map((doc) => {
      const data = doc.data();
      return {
        id: doc.id,
        ...data,
        createdAt: data.createdAt ? data.createdAt.toDate().toISOString() : null,
      };
    }).sort((a, b) => new Date(b.createdAt || 0).getTime() - new Date(a.createdAt || 0).getTime());

    let start = 0;
    if (cursor) {
      const idx = all.findIndex(t => t.id === cursor);
      if (idx >= 0) start = idx + 1;
    }
    const transactions = all.slice(start, start + Number(limit));

    const hasMore = start + Number(limit) < all.length;
    const nextCursor = hasMore && transactions.length > 0 ? transactions[transactions.length - 1].id : null;

    res.json({ transactions, hasMore, nextCursor });
  } catch (err) {
    logger.error({ ip, error: err.message }, "Error fetching transactions");
    res.status(500).json({ error: "Internal server error" });
  }
});

// POST /funds/transactions — admin only: add a transaction
router.post("/transactions", authMiddleware, tenantMiddleware, canManageFunds, validate(CreateTransactionSchema), async (req, res) => {
  const ip = req.ip || req.headers["x-forwarded-for"] || "unknown";
  try {
    const { title, amount, type, note, category, transactionId } = req.body;
    const db = getDb();
    const docRef = await db.collection("transactions").add({
      society_id: req.societyId, // MANDATORY: Multi-tenancy partition
      title,
      amount: Number(amount),
      type,
      category: category || "Other",
      note: note || "",
      transactionId: transactionId || null,
      addedBy: req.user.uid,
      createdAt: getAdmin().firestore.FieldValue.serverTimestamp(),
    });

    res.status(201).json({ id: docRef.id, message: "Transaction recorded" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /funds/summary — total collected, spent, balance, and target (Filtered by societyId)
router.get("/summary", authMiddleware, tenantMiddleware, async (req, res) => {
  try {
    const db = getDb();
    const { redis } = require("../src/shared/Redis");
    const [transSnap, settingsSnap] = await Promise.all([
      db.collection("transactions").where("society_id", "==", req.societyId).limit(500).get(),
      db.collection("society_settings").doc(req.societyId).get()
    ]);

    let totalCredit = 0;
    let totalDebit = 0;
    const categoryBreakdown = {};

    transSnap.forEach((doc) => {
      const d = doc.data();
      if (d.type === "credit") {
        totalCredit += d.amount;
      } else if (d.type === "debit") {
        totalDebit += d.amount;
        const cat = d.category || "Other";
        categoryBreakdown[cat] = (categoryBreakdown[cat] || 0) + d.amount;
      }
    });

    const settings = settingsSnap.exists ? settingsSnap.data() : { target: 200000, currency: "Rs", maintenanceFee: 625 };
    const maintenanceFee = settings.maintenanceFee || 625;

    // AI V3.12: Live Census-based Outstanding Dues Calculation (Filtered by societyId)
    const usersSnap = await db.collection("users")
      .where("society_id", "==", req.societyId)
      .where("status", "==", "approved")
      .get();

    const liableUsers = usersSnap.docs.filter(u => u.data().maintenanceExempt !== true);

    const now = new Date();
    const firstDayMs = new Date(now.getFullYear(), now.getMonth(), 1).getTime();
    // Equality-only query; date range applied in memory (no composite index needed)
    const paidMatch = await db.collection("transactions")
      .where("society_id", "==", req.societyId)
      .where("category", "==", "maintenance")
      .where("type", "==", "credit")
      .get();

    const paidUids = new Set(paidMatch.docs
      .filter(doc => {
        const c = doc.data().createdAt;
        return c && c.toMillis ? c.toMillis() >= firstDayMs : true;
      })
      .map(doc => doc.data().addedBy));
    const unpaidCount = liableUsers.filter(u => !paidUids.has(u.data().uid)).length;

    res.json({
      totalCollected: totalCredit,
      totalSpent: totalDebit,
      balance: totalCredit - totalDebit,
      target: settings.target,
      currency: settings.currency,
      percentage: Math.round((totalCredit / (settings.target || 1)) * 100),
      categoryBreakdown,
      outstandingDues: unpaidCount * maintenanceFee,
      overdueCount: unpaidCount,
      topCategories: Object.keys(categoryBreakdown).sort((a, b) => categoryBreakdown[b] - categoryBreakdown[a]).slice(0, 3).join(", ")
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /funds/settings — admin only: set society-wide financial targets
router.post("/settings", authMiddleware, tenantMiddleware, canManageFunds, async (req, res) => {
  try {
    const { target, currency, maintenanceFee } = req.body;
    const db = getDb();
    const settingsRef = db.collection("society_settings").doc(req.societyId);

    const updates = {};
    if (target !== undefined) updates.target = Number(target);
    if (currency) updates.currency = currency;
    if (maintenanceFee !== undefined) updates.maintenanceFee = Number(maintenanceFee);

    await settingsRef.set(updates, { merge: true });

    // Invalidate dashboard cache
    try {
      const { redis } = require("../src/shared/Redis");
      await redis.del(`admin:dashboard:${req.societyId}`);
    } catch (e) {
      console.warn("Redis invalidation skipped:", e.message);
    }

    await AuditLogService.getInstance().log({
      type: 'administrative',
      action: "Settings Updated",
      actorId: req.user.uid,
      actorName: req.user.name || "Admin",
      details: `Updated society financial settings`,
      society_id: req.societyId,
      metadata: updates
    });

    res.json({ message: "Settings updated successfully" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /funds/maintenance-status (Filtered by societyId)
router.get("/maintenance-status", authMiddleware, tenantMiddleware, async (req, res) => {
  try {
    const db = getDb();
    const admin = getAdmin();

    const usersSnap = await db.collection("users")
      .where("society_id", "==", req.societyId)
      .where("status", "==", "approved")
      .get();

    const liableUsers = usersSnap.docs
      .map(d => ({ uid: d.id, ...d.data() }))
      .filter(u => u.maintenanceExempt !== true);

    const settingsSnap = await db.collection("society_settings").doc(req.societyId).get();
    const maintenanceFee = settingsSnap.exists ? (settingsSnap.data().maintenanceFee || 625) : 625;

    const now = new Date();
    const monthsToCheck = [];
    for (let i = 0; i < 3; i++) {
      const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
      monthsToCheck.push({
        name: d.toLocaleString('default', { month: 'short' }),
        start: admin.firestore.Timestamp.fromDate(d),
        end: admin.firestore.Timestamp.fromDate(new Date(d.getFullYear(), d.getMonth() + 1, 0))
      });
    }

    const oldestDate = monthsToCheck[monthsToCheck.length - 1].start;
    // Equality-only query (merge-joins single-field indexes, no composite needed);
    // apply the date range in memory
    const transSnap = await db.collection("transactions")
      .where("society_id", "==", req.societyId)
      .where("category", "==", "maintenance")
      .where("type", "==", "credit")
      .get();

    const payments = transSnap.docs
      .map(doc => doc.data())
      .filter(t => t.createdAt && t.createdAt.toMillis ? t.createdAt.toMillis() >= oldestDate.toMillis() : true);

    const overdueList = [];
    const paidUids = new Set();

    liableUsers.forEach(user => {
      let monthsMissed = 0;
      monthsToCheck.forEach((month, index) => {
        const hasPaid = payments.some(p =>
          p.addedBy === user.uid &&
          p.createdAt.toMillis() >= month.start.toMillis() &&
          p.createdAt.toMillis() <= month.end.toMillis()
        );

        if (!hasPaid) {
          monthsMissed++;
        } else if (index === 0) {
          paidUids.add(user.uid);
        }
      });

      if (monthsMissed > 0) {
        overdueList.push({
          uid: user.uid,
          name: user.name,
          flatNumber: user.flatNumber,
          amountOwed: monthsMissed * maintenanceFee,
          monthsOverdue: monthsMissed,
          unitInfo: `Unit ${user.flatNumber || 'N/A'} • ${monthsMissed} month${monthsMissed > 1 ? 's' : ''}`
        });
      }
    });

    // PRIVACY: plain residents only get THEIR OWN row — the society-wide
    // paid/unpaid roster (names, flats, amounts) is management data. The app's
    // resident screens only ever look up the caller's own entry; the full list
    // feeds admin dashboards (overdueResidentsProvider).
    const managementRoles = new Set([
      "main_admin", "admin", "treasurer", "secretary", "committee_member",
      "super_admin", "superadmin",
    ]);
    const isManagement = managementRoles.has(String(req.user.role || "").toLowerCase());
    const onlySelf = (rows) => rows.filter(r => r.uid === req.user.uid);

    const paid = liableUsers.filter(u => paidUids.has(u.uid)).map(u => ({ uid: u.uid, name: u.name, flatNumber: u.flatNumber }));
    const unpaid = overdueList.sort((a, b) => b.amountOwed - a.amountOwed);

    res.json({
      paid: isManagement ? paid : onlySelf(paid),
      unpaid: isManagement ? unpaid : onlySelf(unpaid),
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── Phase 2: Payment Integration (Gateway Agnostic) ────────────────
const { PaymentService } = require("../src/services/payment/PaymentService");
const { isRazorpayConfigured, isRazorpayTestMode } = require("../src/services/payment/RazorpayProvider");

// POST /payments/create-order
// NOTE: the canonical, invoice-derived flow is POST /finance/payments/create-order.
// This legacy endpoint is retained for existing clients; the amount is still
// client-supplied here.
router.post("/payments/create-order", authMiddleware, tenantMiddleware, async (req, res) => {
  try {
    if (!isRazorpayConfigured()) {
      return res.status(503).json({ error: "Online payments are not enabled (Razorpay keys not configured)", code: "GATEWAY_DISABLED" });
    }
    const { amount, currency = "INR", receipt } = req.body;

    if (!amount || amount <= 0) {
      return res.status(400).json({ error: "Invalid amount" });
    }

    const provider = PaymentService.getInstance().getProvider();
    const order = await provider.createOrder(amount, currency, receipt);

    res.json({ ...order, testMode: isRazorpayTestMode() });
  } catch (err) {
    logger.error({ error: err.message, user: req.user.uid }, "Order Creation Failed");
    res.status(500).json({ error: err.message });
  }
});

// POST /payments/verify
router.post("/payments/verify", authMiddleware, tenantMiddleware, async (req, res) => {
  try {
    if (!isRazorpayConfigured()) {
      return res.status(503).json({ error: "Online payments are not enabled (Razorpay keys not configured)", code: "GATEWAY_DISABLED" });
    }
    const payload = { ...req.body, ip: req.ip };
    const provider = PaymentService.getInstance().getProvider();
    
    const verification = await provider.verifyPayment(payload);
    
    if (!verification.success) {
      return res.status(400).json({ 
        error: verification.message,
        details: verification.error 
      });
    }

    // ✅ BUG-02 FIX: Use gateway-verified amount, NOT client-supplied amount
    // verifiedAmount comes from Razorpay's own API after signature check
    if (!verification.verifiedAmount) {
      // Gateway fetch failed (e.g. test mode / network issue) — fall back but log a security warning
      logger.warn({ userId: req.user.uid, bodyAmount: req.body.amount }, 'SEC-WARN: Could not verify amount from gateway; using client-supplied amount as fallback');
    }
    const recordedAmount = verification.verifiedAmount ?? Number(req.body.amount);

    // On success: Create transaction record
    const { title, category } = req.body;
    const db = getDb();
    
    const docData = {
      society_id: req.societyId,
      title: title || "Maintenance Payment",
      amount: recordedAmount,
      type: "credit",
      category: category || "maintenance",
      note: `Gateway: ${provider.name} | ID: ${verification.transactionId}`,
      transactionId: verification.transactionId,
      addedBy: req.user.uid,
      createdAt: getAdmin().firestore.FieldValue.serverTimestamp(),
    };

    await db.collection("transactions").add(docData);

    // AI V2.4: Log admin action if it's a significant payment
    await AuditLogService.getInstance().logAdminAction(
      req.user,
      "Payment Verified",
      `Payment of ${recordedAmount} verified via ${provider.name}`
    );

    res.json({ 
      success: true, 
      message: "Payment verified and recorded",
      transactionId: verification.transactionId 
    });
  } catch (err) {
    logger.error({ error: err.message }, "Payment Verification Logic Failed");
    res.status(500).json({ error: err.message });
  }
});

// POST /payments/webhook — Razorpay server-to-server webhook (§7.2c).
// The client callback is never trusted as final: this endpoint validates
// X-Razorpay-Signature (HMAC-SHA256 of the RAW body with
// RAZORPAY_WEBHOOK_SECRET), then marks the payment verified/captured and posts
// it to the Postgres ledger via the idempotent RazorpayWebhookService (one
// financial effect per gateway payment, guaranteed by the payments
// idempotency/unique keys and the payment_webhook_events event store).
router.post("/payments/webhook", async (req, res) => {
  const { RazorpayWebhookService } = require("../src/services/payment/RazorpayWebhookService");
  try {
    if (!process.env.RAZORPAY_WEBHOOK_SECRET) {
      // Fail closed: never accept a webhook signed with a guessable placeholder.
      logger.error({ ip: req.ip }, "SEC-ALERT: RAZORPAY_WEBHOOK_SECRET not configured; rejecting webhook");
      return res.status(503).json({ error: "Webhook not configured" });
    }
    const rawBody = req.rawBody || JSON.stringify(req.body);
    const signature = req.headers["x-razorpay-signature"];
    const eventId = req.headers["x-razorpay-event-id"];
    const result = await RazorpayWebhookService.handle(rawBody, signature, eventId);
    // Always 200 on a valid signature so Razorpay stops retrying.
    res.status(200).json({ ok: true, ...result });
  } catch (err) {
    if (err.code === "INVALID_SIGNATURE") {
      logger.warn({ ip: req.ip }, "SEC-ALERT: Invalid Razorpay webhook signature");
      return res.status(400).json({ error: "Invalid signature" });
    }
    logger.error({ error: err.message }, "Webhook Processing Error");
    res.status(500).json({ error: "Internal Server Error" });
  }
});

// ─── §13: UPI demo QR + admin mark-paid ─────────────────────────────────────
// Lazily required so loading this router never instantiates the Postgres pool
// (unit tests load routes/funds.js without DATABASE_URL).
const getFinanceService = () => require("../src/services/finance/FinanceService").FinanceService;

/** Demo write-paths are allowed outside production, or with ADMIN_DEMO_MODE=true. */
function demoModeEnabled() {
  return process.env.NODE_ENV !== "production" || process.env.ADMIN_DEMO_MODE === "true";
}

// GET /payments/upi-qr?invoiceId= — server-built UPI intent URI + QR PNG for the
// invoice's outstanding balance. Payee comes from backend env config
// (UPI_DEMO_VPA / UPI_DEMO_NAME), never from the client. DEMO/TEST only — the
// QR does not settle anything; an admin confirms via upi-demo/mark-paid.
router.get("/payments/upi-qr", authMiddleware, tenantMiddleware, async (req, res) => {
  try {
    const invoiceId = req.query.invoiceId;
    if (!invoiceId) return res.status(400).json({ error: "invoiceId is required" });

    const FinanceService = getFinanceService();
    const invoice = await FinanceService.getInvoice(req.societyId, String(invoiceId));
    if (!invoice) return res.status(404).json({ error: "Invoice not found" });
    if (invoice.status !== "published") return res.status(409).json({ error: "Only a published invoice can be paid" });

    const { db } = require("../src/shared/Database");
    const amountMinor = await FinanceService.outstandingMinor(db, req.societyId, String(invoiceId));
    if (amountMinor <= 0) return res.status(409).json({ error: "Invoice is already settled" });

    const vpa = process.env.UPI_DEMO_VPA || "sero-demo@upi";
    const payeeName = process.env.UPI_DEMO_NAME || "SERO Demo";
    const amount = (amountMinor / 100).toFixed(2);
    const note = `DEMO ${invoice.number}`;
    const upiUri =
      `upi://pay?pa=${encodeURIComponent(vpa)}&pn=${encodeURIComponent(payeeName)}` +
      `&am=${amount}&cu=INR&tn=${encodeURIComponent(note)}`;

    const QRCode = require("qrcode");
    const dataUrl = await QRCode.toDataURL(upiUri, { width: 320, margin: 2 });
    const qrPngBase64 = dataUrl.replace(/^data:image\/png;base64,/, "");

    res.json({
      upiUri,
      qrPngBase64,
      amountMinor,
      amount: Number(amount),
      currency: "INR",
      payee: { vpa, name: payeeName },
      invoiceId: invoice.id,
      invoiceNumber: invoice.number,
      note: "DEMO/TEST",
    });
  } catch (err) {
    if (err.code === "NOT_FOUND") return res.status(404).json({ error: "Invoice not found" });
    logger.error({ error: err.message }, "UPI QR generation failed");
    res.status(500).json({ error: "Failed to build UPI QR" });
  }
});

// POST /payments/upi-demo/mark-paid {invoiceId, reference} — admin-only DEMO
// confirmation of a UPI QR payment. Allowed only when NODE_ENV !== production
// or ADMIN_DEMO_MODE=true. Settles the invoice through the normal idempotent
// payment recording path (ONE financial effect: payment + allocation + ledger +
// receipt) and writes a demo_payment_audits row (who/when/reference).
router.post("/payments/upi-demo/mark-paid", authMiddleware, tenantMiddleware, canManageFunds, async (req, res) => {
  try {
    if (!demoModeEnabled()) {
      return res.status(403).json({ error: "Demo payments are disabled in production", code: "DEMO_DISABLED" });
    }
    const { invoiceId, reference } = req.body || {};
    if (!invoiceId || !reference || typeof reference !== "string" || !reference.trim()) {
      return res.status(400).json({ error: "invoiceId and reference are required" });
    }

    const result = await getFinanceService().markInvoicePaidDemo(req.societyId, {
      invoiceId: String(invoiceId),
      reference: reference.trim(),
      actorId: req.user.uid,
    });

    await AuditLogService.getInstance().logAdminAction(
      req.user,
      "UPI Demo Payment Marked Paid",
      `Invoice ${invoiceId} marked paid (demo) with reference ${reference.trim()}`
    );

    res.status(result.duplicate ? 200 : 201).json({
      success: true,
      duplicate: result.duplicate,
      payment: result.payment,
      receipt: result.receipt || null,
      invoiceId: result.invoiceId,
      amountMinor: result.amountMinor,
      testMode: true,
    });
  } catch (err) {
    if (err.code === "NOT_FOUND") return res.status(404).json({ error: "Invoice not found" });
    if (err.code === "INVALID_STATE") return res.status(409).json({ error: err.message });
    logger.error({ error: err.message }, "UPI demo mark-paid failed");
    res.status(500).json({ error: "Failed to mark invoice paid" });
  }
});

module.exports = router;
