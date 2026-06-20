# MASTER_EXISTING_IMPLEMENTATION_AUDIT

Audit date: 2026-06-16. All claims cite files/commands actually inspected.

## 1. Backend (`society-backend/`) — SUBSTANTIAL, mostly real

| Area | Evidence | Status |
|---|---|---|
| TypeScript routes | `src/routes/` = 25 files (admin_dashboard.ts, ai.ts, amenities.ts, complaints.ts, finance.ts, guard_pg.ts, members_pg.ts, notices_pg.ts, parking_pg.ts, polls_pg.ts, realtime.ts, reports_pg.ts, resident_pg.ts, rules_pg.ts, society_pg.ts, staff_pg.ts, structure_pg.ts, super_admin.ts, events_pg.ts, meetings.ts, assets_pg.ts, audit_pg.ts, channels_pg.ts, notifications_pg.ts) | Real |
| Legacy JS routes | `routes/` = 13 Firestore-era files (auth.js, users.js, visitors.js, etc.) coexist with `_pg` TS routes | Partial / dual-stack |
| Domain services | `src/services/` per-domain dirs: ai, amenities, assets, audit, channels, complaints, cron, dashboard, events, files, finance, guard, members, notices, notifications, outbox, parking, payment, platform, polls, realtime, reports, resident, rules, sla, society, staff, structure | Real |
| AI services | `src/services/ai/` AIChatService, AICostService, AIEvaluationService, AIExtractionService, AIFeatureFlagService, AIGuardrailsService, AIInnovationService, AIMemoryService, AIPromptService, AIQueueService (+more) | Real |
| Migrations | `migrations/` = 41 files incl. finance core/ledger, RLS enable (`20260616204000_enable_rls.js`), outbox, vector tables, audit partitioning, platform control plane | Real |
| Tests | `__tests__/` = 50+ suites; `npm test` = **51 suites, 267 tests, ALL PASS** (41.5s) | Verified PASS |
| Payments | `services/payment` + `webhook.integration.test.ts` + `payment_webhook_events` migration | Real |
| RLS / tenant isolation | `rls_isolation.integration.test.ts`, `enable_rls` migration | Real, tested |
| Backup/restore | `backup_restore_smoke.integration.test.ts` — **SKIPS real dump** (`pg_dump available=false, DATABASE_URL set=false`) | Smoke only — NOT a restore proof |

**Backend verdict: PARTIALLY VERIFIED — real, well-tested in unit/integration scope.** Not proven at scale; backup/restore is a skipped smoke test, not evidence.

## 2. Flutter app (`sero/lib/`) — REAL provider/service layer, BLOCKED by mock cutover

| Area | Evidence | Status |
|---|---|---|
| Services | `services/` has api_client.dart, api_service.dart, auth_service.dart, ai_service.dart, sse_manager.dart, payment_service.dart, + `services/admin/` (7 services: dashboard, finance, complaint, staff, society, parking, asset) | Real |
| Providers | `providers/admin/`, `providers/shared/` (auth, visitors, issues, notices, events, funds, staff, notification, presence...), `providers/super_admin/`, `providers/ai_copilot/` | Real (Riverpod) |
| Real data path proven | `providers/admin/dashboard_provider.dart:19-24` → `AdminDashboardService.getDashboardSummary()` → `GET /admin/dashboard/summary`, **no mock fallback** | Real, cutover done |
| API base URL | `config/env.dart:5` defaults to `http://10.0.2.2:3001/api/v1` (emulator/dev), `:10` localhost | Dev-only, NOT production |
| Mock flag | `config/dev_config.dart:1` → `const bool kUseMockData = true;` (referenced in 25 lib locations) | **BLOCKER** |
| Admin screens on mock | **29 screen files** still `import 'package:sero/data/mock_data.dart'` and render static `MockDashboardData`/`MockFinanceData` constants (all zeroed) instead of providers | **BLOCKER** |

**Frontend verdict: BLOCKED.** Provider/service plumbing to the real backend exists and dashboard is cut over, but `kUseMockData=true` and 29 admin screens read zeroed static constants. User-visible effect: admin UI shows empty/zero data instead of live backend data.

## 3. Per-area application status (summary)
| Area | Backend | Frontend | Net |
|---|---|---|---|
| Login/Auth | Real (auth routes + tests) | Real (auth_service/provider) | Partial-Verified |
| Super Admin | Real (super_admin.ts + 3 test suites) | Provider exists | Partial |
| Admin | Real (`_pg` routes) | Mixed — dashboard cut over, ~29 screens on mock | Blocked |
| Staff/Guard | Real (staff_pg, guard_pg + tests) | Provider exists | Partial |
| Resident | Real (resident_pg + tests) | Screens present | Partial |
| AI Copilot | Real (full AI service suite + 4 AI test suites) | ai_service + ai_copilot provider | Partial |
| Cross-role | Backend services exist | Not end-to-end proven | Unverified |

## 4. What was NOT verified (honesty)
- No cross-role end-to-end journey was executed (Section 9).
- No load test run (Section 10/11) — see capacity report.
- No physical-device APK install (Section 11) — see APK gate.
- Backup/restore is a skipped smoke test, not a real restore.
