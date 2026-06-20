# AI Data Asset Inventory

**Date:** 2026-06-16
**Data Architect:** Chief AI Product Officer

This inventory maps all operational database tables to AI-useable data assets in SERO.

## 1. Table-to-Asset Mapping

| Table Name | Primary Fields Used | AI Use Case | Data Type | Volume/Frequency |
|---|---|---|---|---|
| `complaints` | `id, title, category_id, status, unit_id, created_at, resolved_at` | Root-cause analysis, duplication detection, SLA forecasting. | Transactional / Text | Medium (Daily) |
| `expenses` | `id, category, vendor, amount_minor, created_at` | Expense spike detection, duplicate billing alerts. | Financial | Medium (Weekly) |
| `assets` | `id, name, type, commissioned_on, status` | Asset risk calculation, maintenance prediction. | Structural / Metadata | Low (Infrequent) |
| `maintenance_work_orders` | `id, asset_id, kind, status, completed_at, cost_minor` | Down-time scoring, MTBF forecasting. | Operational | Medium (Weekly) |
| `payments` | `id, society_id, status, amount_minor, captured_at` | Cash-flow forecasting, collection efficiency. | Financial | High (Monthly peaks) |
| `invoices` | `id, society_id, status, total_minor, due_date` | Late-payment modeling, smart collection schedules. | Financial | High (Monthly peaks) |
| `polls` / `votes` | `id, options, vote_scope, created_at` | Community pulse, engagement metrics. | Governance | Low (Weekly) |
| `notices` | `id, status, created_at, target_audience` | Audience targeting, engagement decline detection. | Communication | Low (Weekly) |

## 2. Derived Assets (Feature Store Context)
- **Asset Health Metrics:** Aggregated MTBF and daily downtime averages.
- **Resident Payment Scorecard:** Historical payment delays and installment plan adherence metrics (never exposed to third parties; strictly RLS-isolated).
- **Category-wise Expense Vectors:** Vectorized historical expense trends for anomaly radar.
