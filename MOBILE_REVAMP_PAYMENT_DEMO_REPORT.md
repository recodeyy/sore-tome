# MOBILE_REVAMP_PAYMENT_DEMO_REPORT

> 2026-07-07. Resolves §7.2 + §13. Backend proof: `society-backend/__tests__/payment_demo.integration.test.ts` (all pass, part of 310-green suite).

## Backend payment stack (migration `20260707120000_payment_demo_stack.js`)

Tables: `invoices`, `invoice_lines`, `payments`, `payment_allocations`, `receipts`, `payment_webhook_events`, `demo_payment_audits`, `booking_payments`. Double-entry ledger posting on capture.

## Test matrix (all ✅)

| Scenario | Requirement (§13) | Assertion |
|---|---|---|
| Razorpay checkout verify idempotency | duplicate taps → one payment | duplicate verify ⇒ exactly **one** payment row, **one** receipt, **balanced** ledger |
| Bad signature | backend verifies signature | bad signature ⇒ **rejected** (`SEC-ALERT` logged) |
| Duplicate webhook | duplicate webhooks → one financial effect | webhook after checkout for same gateway payment ⇒ **no second effect** |
| Receipt generation | auto receipt + PDF | capture ⇒ **numbered** receipt, renders a real `%PDF` with **"TEST MODE"** watermark |
| UPI demo mark-paid | admin demo-mode only + audit | settles invoice **once** (idempotent on reference) + writes `demo_payment_audits` row |
| Dues reminders | dues reminder push | overdue invoices notified **at most once per day** |

## App payment UX (`sero/lib/screens/resident/payments/`)

- `bills_dues_screen` — maintenance + utility (electricity/water/maintenance) bills, line items, due date, outstanding, late fee, status chip.
- `pay_invoice_sheet` — Razorpay Test Mode checkout; UI shows **Processing** until backend verifies (client callback is *not* treated as proof).
- `upi_qr_screen` — backend-generated UPI QR / deep link, clearly labelled demo/test.
- `receipts_screen` + `receipt.dart` model — download/share PDF receipt, offline-saved receipts, payment history.
- `payment_status_chip.dart` — success/pending/failed/refund-demo states.

## Safety properties enforced

1. Client callback is never final proof — backend Razorpay signature/webhook verification gates receipt + ledger.
2. Duplicate UI taps and duplicate webhooks are idempotent (one financial effect).
3. UPI manual mark-paid only under `ADMIN_DEMO_MODE` with an audit row.
4. Razorpay stays in **Test Mode**; `RAZORPAY_KEY_SECRET`/webhook secret never leave the server.

## Limitation

Real bank settlement is **not** claimed. This is a Razorpay **Test Mode** / demo-UPI flow end to end.
