# SERO Backend — QC Findings & Feature-Completeness Matrix

**Date:** 2026-06-16 · tsc: 0 errors · jest: 48 suites / 246 tests passing

## Feature-Completeness Matrix

Legend: ✅ implemented + tested · ◑ implemented, thin/partial coverage · ✖ missing

| Module | Status | Service evidence | Test evidence |
|--------|--------|------------------|---------------|
| Auth / role-portal login | ✅ | `routes/*`, portal-mismatch check | `auth.test.js`, `auth_portal.integration.test.js` |
| Admin dashboard | ✅ | `routes/admin_dashboard.ts`, `DashboardService.ts` | `dashboard.integration.test.ts` |
| Society setup | ✅ | `services/society/SocietyService.ts` | `society_setup.integration.test.ts` |
| Members lifecycle | ✅ | `members/MemberService.ts` | `member.integration.test.ts` |
| Structure (wings/blocks/units) | ✅ | `structure/` | `structure.integration.test.ts` |
| Bulk import | ✅ | `structure/BulkImportService.ts` | `bulk_import.integration.test.ts` |
| Finance: billing/invoices | ✅ | `finance/FinanceService.ts` | `finance_billing.integration.test.ts`, `finance.integration.test.ts` |
| Finance: ledger (debit=credit) | ✅ | `finance/ledger.ts` | `finance.integration.test.ts` |
| Finance: payments/receipts | ✅ | `FinanceService.ts` (13 receipt refs) | `finance.integration.test.ts`, `webhook.integration.test.ts` |
| Finance: credit notes | ◑ | `FinanceService.ts` (creditNote) | covered indirectly; no dedicated credit-note test |
| Finance: recurring | ◑ | `FinanceService.ts` (recurring x6) | no dedicated recurring test file |
| Finance: late fee / waiver | ◑ | `FinanceService.ts` (LateFee, waiver) | thin |
| Finance: expenses + approval | ✅ | `finance/ExpenseService.ts` | `expense.integration.test.ts` |
| Finance: reconciliation | ✅ | `finance/ReconciliationService.ts` | `reconciliation.integration.test.ts` |
| Finance: reports | ✅ | `finance/FinanceReportService.ts` | `finance-report.integration.test.ts` |
| Payment webhook (idempotent) | ✅ | razorpay handler | `webhook.integration.test.ts` (duplicate-ignored asserted) |
| Complaints + SLA | ✅ | `complaints/ComplaintService.ts`, `ComplaintStateMachine.ts` | `complaint.integration.test.ts`, `complaint_escalation.integration.test.ts`, `sla.test.ts` |
| Notices | ✅ | `services/notices` | `notice.integration.test.ts`, `notices.test.js` |
| Polls | ✅ | `services/polls` | `poll.integration.test.ts` |
| Events | ✅ | `services/events` | `event.integration.test.ts` |
| Meetings | ✅ | `services/meetings` | `meeting.integration.test.ts` |
| Rules | ✅ | `services/rules` | `rule.integration.test.ts` |
| Channels | ✅ | `services/channels` | `channel.integration.test.ts`, `channels.test.js` |
| Staff CRUD/attendance/roster/leave/payroll/overtime/KYC/reports | ✅ | `staff/StaffService.ts` (all keywords present) | `staff.integration.test.ts`, `staff_pack.integration.test.ts` |
| Amenities booking/blackouts/pricing/reschedule/reviews | ✅ | `amenities/BookingService.ts` | `booking.integration.test.ts`, `amenity_enhance.integration.test.ts` |
| Amenities analytics | ✅ | analytics | `amenity_analytics.integration.test.ts` |
| Parking | ✅ | `services/parking` | `parking.integration.test.ts` |
| Assets / work orders | ✅ | `services/assets` | `asset.integration.test.ts` |
| Notifications | ✅ | `services/notifications` | `notification.integration.test.ts` |
| Realtime / outbox | ✅ | `services/outbox`, `services/realtime` | `outbox.integration.test.ts`, `eventbus.unit.test.ts` |
| RLS / tenant isolation | ◑ | `shared/Database.ts` injects `app.society_id`; policies referenced in society/rules/complaints/finance | no dedicated cross-tenant RLS test asserting Society A↛B |
| Dashboard analytics/search/activity/preferences | ✅ | `dashboard/{AnalyticsService,SearchService,ActivityService,PreferenceService}.ts` | `dashboard.integration.test.ts` |
| AI chatbot (tool-permission map, RAG, multilingual) | ✅ | `ai/AIToolService.ts` (role→tool registry + normalizeRole + Hindi/locale), `AIChatService.ts`, `VectorStoreService.ts`, `SemanticCacheService.ts` | `ai_chat`, `ai_tool_authorization`, `ai_multilingual` integration tests |
| AI innovation (pulse/clusters/anomalies/predictions) | ✅ | `ai/AIInnovationService.ts` (all four present) | `ai_innovation.integration.test.ts` |
| Super-admin control plane (lifecycle/subscriptions/plans/config/white-label/api-keys/webhooks/support/impersonation/audit) | ✅ | `platform/SuperAdminService.ts` (all keywords present) | `super_admin`, `super_admin_config`, `super_admin_depth` integration tests |
| Resident self-scoped module | ✅ | `resident/ResidentService.ts` | `resident.integration.test.ts` |
| Guard module | ✅ | `guard/GuardService.ts` | `guard.integration.test.ts` |
| Audit logging (partitioned) | ✅ | `AuditLogService.ts`, range-partition migration | exercised across suites |

**Tally:** Fully done (✅): ~33 · Partial (◑): 5 (credit-notes, recurring, late-fee/waiver dedicated tests; RLS cross-tenant assertion) · Missing (✖): 0 backend modules.

## Defects

| ID | Sev | Module | File | Description |
|----|-----|--------|------|-------------|
| QC-01 | P2 | Tenant isolation | `src/shared/Database.ts:55` | RLS tenant context set via session-level `SET app.society_id` per pooled query, not `SET LOCAL` inside a tx. Safe under current connect-per-query pattern but fragile; no automated test proves Society A cannot read Society B rows. Add a cross-tenant RLS regression test. |
| QC-02 | P2 | Test hygiene | jest run | "Force exiting Jest — open handles." DB/Redis singletons not closed in teardown; risks flaky CI and masked leaks. |
| QC-03 | P2 | Finance | `FinanceService.ts` | credit-notes, recurring billing, late-fee/waiver implemented but lack dedicated regression tests; correctness of recurring schedule generation unverified by suite. |
| QC-04 | P3 | Out of scope | — | No executed evidence for load (3–5k users), backup/restore, file-upload security, AI red-team, or Flutter client E2E. Required before unconditional production sign-off. |

No P0/P1 found by static reading. Finance ledger posting enforces debit=credit and webhook idempotency is asserted by passing tests, mitigating the highest-risk financial-corruption category.
