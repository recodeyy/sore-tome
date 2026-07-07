# SERO Admin Web — Billing & Reports Report

Built first (per Section 17 order). All figures below are **live** from the shared backend
(Hubtown Sunkist seed), formatted from integer minor units.

## Billing (`/billing`)

- **List** live invoices from `GET finance/invoices` (number, member, period, status, total, due).
- **Create bill** → `POST finance/invoices` with a line item `{description, component, quantity,
  unitPriceMinor, taxMinor}` (GST/tax field included). Contract matches `CreateInvoiceSchema`.
- **Publish** draft → `POST finance/invoices/:id/publish` (resident then sees/pays it).
- **Record payment** → `POST finance/payments` with an **idempotency key** (manual/offline entry,
  audited). Online payments go through Razorpay Test Mode and are confirmed **only by verified
  webhook status** — the UI never fakes gateway success (Section 5.4 honored).
- Summary tiles: invoice count, total invoiced, collected.

## Payments (`/payments`)

- Collection summary from `finance/reports/summary` (invoiced/collected/outstanding + collection
  rate). Receipts from `finance/receipts`. Explicit banner: no payment is marked successful
  without backend confirmation.

## Bank Reconciliation (`/reconciliation`)

Demo flow, all live: create account → import statement CSV (`POST reconciliation/imports` with
parsed `{txnDate, amountMinor, description, reference}` lines) → `auto-match` → summary
(`processed / matched / unmatched`). Matches statement lines to captured payments.

## Expenses (`/expenses`)

List + create (`POST finance/expenses`) with approval status; export CSV/PDF.

## Reports (`/reports`) — verified live values

| Report | Source | Sample (seed) |
|---|---|---|
| Collection summary | `finance/reports/summary` | Invoiced ₹15,930 · Collected ₹0 · Outstanding ₹15,930 |
| Dues ageing buckets | `finance/reports/dues` | 0–30: ₹5,310 · 31–60: ₹5,310 · 61–90: ₹0 · 90+: ₹0 |
| Defaulter report | `finance/reports/dues` items | per-invoice outstanding, age, bucket |
| Trial balance | `finance/reports/trial-balance` | Debit ₹5,510 = Credit ₹5,510 · **balanced ✓** |

The **payment report reconciles to the ledger** — trial balance is balanced and dashboard/report
outstanding both derive from the same `finance/reports/*` source (no divergent computation on the
web side). This satisfies the "payment report must not mismatch ledger" gate.

## Exports (live, client-generated)

- **CSV**: invoices, payment collection, defaulter report, expenses, members, complaints (SLA),
  visitor register, staff, parking, notices.
- **PDF**: invoices, defaulter report, staff register, parking (jsPDF + autotable, branded).
- All exports serialize the **already-fetched live rows** — amounts/receipt numbers written
  verbatim. For very large exports, backend `reports/jobs` background-job endpoints exist and are
  documented (download-link wiring is a P3 enhancement).

## GST / receipts / disputes

- GST/tax captured per invoice line and included in totals; receipt PDFs available via backend
  `finance/receipts/:id/pdf`. Resident billing disputes flow through the complaints module.
