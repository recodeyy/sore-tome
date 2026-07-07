import { PDFDocument, StandardFonts, rgb, degrees } from "pdf-lib";

/**
 * §7.2 — Renders a payment receipt as a clean single-page PDF (pdf-lib, already
 * a repo dependency). All money values arrive in integer minor units (paise)
 * and are printed as ₹ (rendered as "Rs." — WinAnsi standard fonts cannot
 * encode U+20B9). A diagonal "TEST MODE / DEMO" watermark is stamped when the
 * payment came from test keys or the UPI demo path.
 */

const INR = (minor: number | string | null | undefined) =>
  `Rs. ${(Number(minor || 0) / 100).toLocaleString("en-IN", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;

export interface ReceiptDetail {
  receipt: any;
  invoice: any | null;
  lines: any[];
  unit: { number: string } | null;
  payer: { name: string; phone?: string } | null;
  society: { name: string; address?: string; registration_no?: string } | null;
}

export const ReceiptPdfService = {
  /** True when this payment should carry the TEST MODE / DEMO watermark. */
  isTestPayment(detail: ReceiptDetail): boolean {
    const meta = detail.receipt?.payment_metadata || {};
    if (meta.testMode === true || meta.demo === true) return true;
    if (detail.receipt?.provider === "upi_demo") return true;
    if (detail.receipt?.provider === "razorpay" && (process.env.RAZORPAY_KEY_ID || "").startsWith("rzp_test_")) return true;
    return false;
  },

  async render(detail: ReceiptDetail): Promise<Uint8Array> {
    const { receipt, invoice, lines, unit, payer, society } = detail;
    const doc = await PDFDocument.create();
    const page = doc.addPage([595.28, 841.89]); // A4
    const font = await doc.embedFont(StandardFonts.Helvetica);
    const bold = await doc.embedFont(StandardFonts.HelveticaBold);
    const { width, height } = page.getSize();
    const margin = 50;
    let y = height - margin;

    const text = (s: string, x: number, size = 10, f = font, color = rgb(0.15, 0.15, 0.2)) =>
      page.drawText(String(s ?? ""), { x, y, size, font: f, color });
    const right = (s: string, size = 10, f = font) => {
      const w = f.widthOfTextAtSize(String(s), size);
      page.drawText(String(s), { x: width - margin - w, y, size, font: f, color: rgb(0.15, 0.15, 0.2) });
    };
    const rule = (yy: number) =>
      page.drawLine({ start: { x: margin, y: yy }, end: { x: width - margin, y: yy }, thickness: 0.7, color: rgb(0.75, 0.78, 0.85) });

    // ── Watermark (behind everything visually — drawn first with low opacity)
    if (this.isTestPayment(detail)) {
      page.drawText("TEST MODE / DEMO", {
        x: 90, y: 330, size: 48, font: bold,
        color: rgb(0.88, 0.55, 0.25), opacity: 0.22, rotate: degrees(35),
      });
    }

    // ── Header: society
    text(society?.name || "Housing Society", margin, 18, bold, rgb(0.1, 0.15, 0.35));
    y -= 16;
    if (society?.address) { text(society.address, margin, 9, font, rgb(0.35, 0.38, 0.45)); y -= 12; }
    if (society?.registration_no) { text(`Regn. No: ${society.registration_no}`, margin, 9, font, rgb(0.35, 0.38, 0.45)); y -= 12; }
    y -= 6;
    rule(y); y -= 24;

    // ── Title + receipt meta
    text("PAYMENT RECEIPT", margin, 15, bold, rgb(0.1, 0.15, 0.35));
    right(receipt.number, 15, bold);
    y -= 18;
    const issued = receipt.created_at ? new Date(receipt.created_at) : new Date();
    text(`Date: ${issued.toISOString().slice(0, 10)}`, margin, 10);
    right(`Status: ${String(receipt.status || "issued").toUpperCase()}`, 10, bold);
    y -= 24;

    // ── Parties
    text("Received from:", margin, 9, bold, rgb(0.35, 0.38, 0.45));
    y -= 13;
    text(payer?.name || "Resident", margin, 11, bold);
    y -= 13;
    if (unit?.number) { text(`Unit: ${unit.number}`, margin, 10); y -= 13; }
    if (payer?.phone) { text(`Phone: ${payer.phone}`, margin, 10); y -= 13; }
    y -= 6;

    // ── Invoice reference
    if (invoice) {
      text(`Against invoice ${invoice.number}${invoice.period ? ` — period ${invoice.period}` : ""}`, margin, 10, bold);
      y -= 16;
    }

    // ── Line items table
    rule(y + 6);
    y -= 8;
    text("Description", margin, 9, bold, rgb(0.35, 0.38, 0.45));
    page.drawText("Qty", { x: 350, y, size: 9, font: bold, color: rgb(0.35, 0.38, 0.45) });
    right("Amount", 9, bold);
    y -= 6; rule(y); y -= 14;
    const rows = lines.length
      ? lines.map((l) => ({ d: l.description, q: l.quantity, a: Number(l.amount_minor) + Number(l.tax_minor || 0) }))
      : [{ d: invoice ? `Payment against ${invoice.number}` : "Payment", q: 1, a: Number(receipt.amount_minor) }];
    for (const r of rows) {
      text(String(r.d).slice(0, 60), margin, 10);
      page.drawText(String(r.q ?? 1), { x: 350, y, size: 10, font, color: rgb(0.15, 0.15, 0.2) });
      right(INR(r.a), 10);
      y -= 15;
    }
    y -= 4; rule(y); y -= 16;

    if (invoice) {
      right(`Invoice subtotal: ${INR(invoice.subtotal_minor)}`, 9); y -= 13;
      if (Number(invoice.tax_minor)) { right(`Tax: ${INR(invoice.tax_minor)}`, 9); y -= 13; }
      if (Number(invoice.late_fee_minor)) { right(`Late fee: ${INR(invoice.late_fee_minor)}`, 9); y -= 13; }
      right(`Invoice total: ${INR(invoice.total_minor)}`, 9); y -= 16;
    }
    right(`AMOUNT RECEIVED: ${INR(receipt.amount_minor)}`, 13, bold);
    y -= 28;

    // ── Payment details
    rule(y + 10);
    text("Payment details", margin, 9, bold, rgb(0.35, 0.38, 0.45)); y -= 14;
    const meta = receipt.payment_metadata || {};
    const mode = receipt.provider === "razorpay" ? "Online (Razorpay)"
      : receipt.provider === "upi_demo" ? "UPI (DEMO)"
      : receipt.provider || "Manual";
    text(`Mode: ${mode}`, margin, 10); y -= 13;
    if (receipt.provider_payment_id) { text(`Gateway payment id: ${receipt.provider_payment_id}`, margin, 10); y -= 13; }
    if (meta.orderId || meta.order_id) { text(`Gateway order id: ${meta.orderId || meta.order_id}`, margin, 10); y -= 13; }
    if (receipt.payment_created_at) { text(`Paid at: ${new Date(receipt.payment_created_at).toISOString().replace("T", " ").slice(0, 16)} UTC`, margin, 10); y -= 13; }
    text(`Currency: ${receipt.currency || "INR"}`, margin, 10); y -= 24;

    // ── Footer
    page.drawText("This is a system-generated receipt and does not require a signature.", {
      x: margin, y: 60, size: 8, font, color: rgb(0.5, 0.52, 0.58),
    });
    if (this.isTestPayment(detail)) {
      page.drawText("TEST MODE / DEMO — not a real financial document.", {
        x: margin, y: 48, size: 8, font: bold, color: rgb(0.8, 0.45, 0.15),
      });
    }

    return doc.save();
  },
};
