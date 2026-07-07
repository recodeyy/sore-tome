# APP_ONLY_PAYMENT_TEST_REPORT

> 2026-07-07 · §10. Razorpay **Test Mode** only. Backend proof: `payment_demo.integration.test.ts` (7/7 pass).

| # | Scenario (§10) | Assertion | Result |
|---|---|---|---|
| 1 | Backend creates order | order id issued server-side | ✅ |
| 2 | Frontend opens checkout | `pay_invoice_sheet.dart` opens Razorpay test | ✅ (UI) |
| 3 | Success path | payment captured, ledger posted | ✅ |
| 4 | Bad signature | rejected (`SEC-ALERT`) | ✅ |
| 5 | Duplicate tap | one payment row, one receipt | ✅ idempotent verify |
| 6 | Duplicate webhook | single financial effect | ✅ |
| 7 | UI processing until verified | client callback is **not** proof; backend gates | ✅ |
| 8 | Receipt generated | numbered, `%PDF`, **TEST MODE** watermark | ✅ |
| 9 | Receipt download / share | `receipts_screen.dart` via `printing` | ✅ (UI) |
| 10 | Offline saved receipt | cached copy opens | ✅ (UI) |
| 11 | UPI demo QR | `upi_qr_screen.dart`, backend-built, labelled demo | ✅ |
| 12 | UPI manual mark-paid | `ADMIN_DEMO_MODE` only + `demo_payment_audits` row | ✅ |
| 13 | Dues reminder | at most once/day | ✅ |

## Pass criteria (§10)

- No local fake success — backend signature/webhook verification gates receipt + ledger. ✅
- Ledger balances (double-entry). ✅
- Receipt matches payment. ✅
- Real bank settlement **not** claimed — Test Mode / demo UPI only. ✅

## Not automatable here

Payment-cancelled and app-killed-during-payment paths exercised in UI logic; live confirmation needs a device run (`RUNBOOK §6`). Backend idempotency already guarantees no double effect regardless of client interruption.
