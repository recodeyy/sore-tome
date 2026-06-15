import crypto from "crypto";
import { db } from "../../shared/Database";
import { logger } from "../../shared/Logger";
import { FinanceService } from "../finance/FinanceService";

/**
 * Razorpay webhook processing.
 * Security: verifies the HMAC-SHA256 signature against the RAW request body using
 * RAZORPAY_WEBHOOK_SECRET. Idempotency: each event_id is stored once; repeated
 * deliveries are ignored, and the downstream ledger posting is itself idempotent.
 *
 * The order must carry `notes.societyId` and `notes.invoiceId` so a captured
 * payment can be allocated to the right invoice.
 */
export const RazorpayWebhookService = {
  verifySignature(rawBody: string, signature: string | undefined): boolean {
    const secret = process.env.RAZORPAY_WEBHOOK_SECRET;
    if (!secret || !signature) return false;
    const expected = crypto.createHmac("sha256", secret).update(rawBody).digest("hex");
    const a = Buffer.from(expected);
    const b = Buffer.from(signature);
    return a.length === b.length && crypto.timingSafeEqual(a, b);
  },

  /**
   * @returns the outcome; throws { code: 'INVALID_SIGNATURE' } if the signature fails.
   */
  async handle(rawBody: string, signature: string | undefined, eventIdHeader?: string) {
    if (!this.verifySignature(rawBody, signature)) {
      throw Object.assign(new Error("Invalid webhook signature"), { code: "INVALID_SIGNATURE" });
    }

    const event = JSON.parse(rawBody);
    const payment = event?.payload?.payment?.entity;
    // Prefer Razorpay's event id header; fall back to the payment id + event type.
    const eventId = eventIdHeader || (payment?.id ? `${payment.id}:${event.event}` : null);
    if (!eventId) {
      return { duplicate: false, processed: false, reason: "no_event_id" };
    }

    const societyId = payment?.notes?.societyId || null;

    // Store the event once; a repeat is a duplicate delivery.
    const inserted = await db.query(
      `INSERT INTO payment_webhook_events (provider, event_id, event_type, society_id, signature_valid, payload)
       VALUES ('razorpay', $1, $2, $3, true, $4)
       ON CONFLICT (provider, event_id) DO NOTHING
       RETURNING id`,
      [eventId, event.event, societyId, JSON.stringify(event)]
    );
    if (inserted.rows.length === 0) {
      logger.info({ eventId }, "Razorpay webhook: duplicate event ignored");
      return { duplicate: true, processed: false };
    }

    if (event.event !== "payment.captured") {
      await db.query(`UPDATE payment_webhook_events SET processed = true WHERE event_id = $1 AND provider = 'razorpay'`, [eventId]);
      return { duplicate: false, processed: true, reason: "ignored_event_type" };
    }

    const invoiceId = payment?.notes?.invoiceId;
    if (!societyId || !invoiceId) {
      const reason = "missing_society_or_invoice_in_notes";
      await db.query(`UPDATE payment_webhook_events SET error = $2 WHERE event_id = $1 AND provider = 'razorpay'`, [eventId, reason]);
      logger.warn({ eventId }, `Razorpay webhook: ${reason}`);
      return { duplicate: false, processed: false, reason };
    }

    // amount is in paise (minor units) already.
    const { duplicate } = await FinanceService.recordPayment(societyId, {
      idempotencyKey: `rzp:${payment.id}`,
      invoiceId,
      amountMinor: Number(payment.amount),
      provider: "razorpay",
      providerPaymentId: payment.id,
      metadata: { order_id: payment.order_id, event: event.event },
    });

    await db.query(`UPDATE payment_webhook_events SET processed = true WHERE event_id = $1 AND provider = 'razorpay'`, [eventId]);
    logger.info({ eventId, paymentId: payment.id, invoiceId, ledgerDuplicate: duplicate }, "Razorpay webhook processed");
    return { duplicate: false, processed: true };
  },
};
