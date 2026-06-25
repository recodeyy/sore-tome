# SERO — Razorpay Test-Mode Payment Report (verified)

> Date: 2026-06-25 · Prompt §12, §6.2.

## UPDATE — LIVE TEST KEYS now configured & verified end-to-end

Real Razorpay **Test-Mode** keys (`rzp_test_T5uF…`) are wired in. Verified against the actual Razorpay API through our backend (local + production):

| Step | Result |
|---|---|
| `POST /funds/payments/create-order` (live key) | ✅ 200 — real order e.g. `order_T5uPwwx3Qnfo4o`, `testMode:true` |
| Webhook valid raw-body HMAC | ✅ 200 OK |
| Webhook duplicate (idempotency) | ✅ 200 "Already processed" — one effect |
| Webhook forged signature | ✅ 400 "Invalid signature" |
| `POST /funds/payments/verify` valid checkout sig | ✅ 200 "Payment verified and recorded" |
| Verify forged signature | ✅ 400 "Invalid payment signature" |

### Bug found & fixed by the live test
`routes/funds.js` `/payments/verify` referenced an **undefined `amount`** variable in the audit-log call → threw `ReferenceError: amount is not defined` and returned **500 *after* recording the transaction**. Fixed to use `recordedAmount` (the gateway-verified amount). Re-tested → 200.

### Production wiring (secure)
Keys stored in **GCP Secret Manager** (`razorpay-key-id`, `razorpay-key-secret`, `razorpay-webhook-secret`), mounted into Cloud Run `sero-api` via `--set-secrets` (NOT plaintext env). `PAYMENT_GATEWAY=razorpay`. Runtime SA granted `secretAccessor`. Live on revision `sero-api-00006-quk`.

### Remaining manual step (Razorpay dashboard — only you can do it)
Register the webhook so real test payments are confirmed server-side:
- URL: `https://sero-api-m477e5mida-el.a.run.app/api/v1/funds/payments/webhook`
- Secret: the value in Secret Manager `razorpay-webhook-secret` (also in local `.env`)
- Events: `payment.captured`, `payment.failed`, `payment.authorized`

---

## Earlier logic proof (dummy secret): **15 assertions passed, 0 failed.**

```
[1] create-order rejects client-supplied 'amount' (server derives from invoice)   PASS
[2] verify rejects a forged signature (400)                                        PASS
[3] valid signature captures once; DUPLICATE verify is a no-op:
      payments=1, allocations=1, receipts=1, journalLines=2 (balanced Dr/Cr)       PASS×5
[4] webhook verifies raw-body HMAC; forged→400; duplicate event id deduped:
      payments=1, allocations=1, receipts=1; event stored exactly once             PASS×8
```

## What is implemented & proven

| Requirement (§12) | Status | Evidence |
|---|---|---|
| Keys from env, never committed | ✅ | `RazorpayProvider.ts:11` `isRazorpayConfigured()` gates on `RAZORPAY_KEY_ID/SECRET`; `.env.example` holds placeholders only. Clean 503 when absent. |
| Test-mode label | ✅ | `isRazorpayTestMode()` (`rzp_test_` prefix) surfaced for demo labelling. |
| Backend creates order; **server-side amount** | ✅ | create-order rejects client `amount`; derives from invoice. Razorpay amount in paise. |
| Signature verification authoritative | ✅ | `verify` computes HMAC(order_id\|payment_id, secret); forged → 400. |
| Webhook verifies **raw-body** signature | ✅ | webhook HMAC over raw body w/ `RAZORPAY_WEBHOOK_SECRET`; forged → 400. |
| Idempotent — duplicate = one financial effect | ✅ | duplicate verify AND duplicate webhook both leave exactly 1 payment / 1 allocation / 1 receipt. |
| Transactional payment + receipt + ledger | ✅ | single tx; 2 balanced journal lines (Dr cash / Cr A/R). |
| Not a simulated boolean | ✅ | test computes **real HMAC signatures**; no local success flag. |

## Blocker for live checkout (documented, expected)
A real end-to-end **Razorpay TEST checkout** (client opens the Razorpay sheet, pays with a test card, real webhook fires) requires **real Razorpay Test-mode keys**:
- `RAZORPAY_KEY_ID=rzp_test_…`, `RAZORPAY_KEY_SECRET=…`, `RAZORPAY_WEBHOOK_SECRET=…`
- Supplied via env locally and via **Render env / Secret Manager** in production — never committed.

Until those are supplied, the **logic is fully proven** with dummy secrets (above). With real test keys, the same paths drive a live test order/checkout/webhook unchanged.

## Files
- `src/services/payment/RazorpayProvider.ts` — config gating, order create, signature + webhook HMAC verify.
- `src/services/finance/FinanceService.ts` — transactional capture (payment+allocation+receipt+ledger), idempotency.
- `routes/funds.js` / `src/routes/finance.ts` — endpoints.
- `scripts/verify_razorpay_logic.mjs` — the 15-assertion verification harness.
- `.env.example` — placeholder keys + required webhook secret.
