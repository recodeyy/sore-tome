# MASTER_FINANCIAL_INVARIANT_REPORT

**Date:** 2026-06-16
**Author:** Treasurer / Security Lead

This report validates the accounting integrity and financial invariants of the SERO ledger.

## 1. Accounting Invariants
- **Double Entry Compliance:** Verified by `finance.integration.test.ts` (PASS). For every transaction, debits equal credits.
- **Floating Point Money ban:** Minor integer values (`amount_minor`) are stored in database columns. Real currency values are computed by division by 100 on output rendering, preventing floating-point drift.
- **Receipt & Invoice Immutability:** Once published, invoices cannot be modified. Credit notes are issued as separate sequential tracking rows.
- **Webhook Idempotency:** Duplicate Razorpay payloads are ignored by event ID tracking, ensuring money is never credited twice (verified by `webhook.integration.test.ts` PASS).
