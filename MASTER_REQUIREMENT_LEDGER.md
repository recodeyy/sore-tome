# MASTER_REQUIREMENT_LEDGER

Audit date: 2026-06-16. Requirements extracted from the 9 available canonical packs (individual canonical files missing — see inventory blockers). Status reflects **evidence actually found**, not aspiration. This is a representative ledger of major capabilities (not padded to thousands of rows, per instruction).

Status legend: Complete = production code + connected + evidence; Partial = exists but unconnected/untested/mock; Missing = no real impl. Priority: P0 (release-critical), P1, P2, P3.

| ID | Source pack | Requirement (summary) | Role/Module | Prio | Status | Evidence |
|---|---|---|---|---|---|---|
| CORE-BE-01 | Backend | PostgreSQL as source of truth + migrations | Backend | P0 | Complete | `society-backend/migrations/` 41 files |
| CORE-BE-02 | Backend | RLS tenant isolation | Backend/Sec | P0 | Complete | `migrations/20260616204000_enable_rls.js`; `__tests__/rls_isolation.integration.test.ts` PASS |
| CORE-BE-03 | Backend | Central permission/RBAC model | Backend | P0 | Partial | `src/middleware`/route guards; negative-auth tests exist (`ai_tool_authorization`) — not exhaustively audited |
| CORE-BE-04 | Backend | Outbox/audit/idempotency | Backend | P1 | Complete | `migrations/...create_outbox.js`; `outbox.integration.test.ts` PASS |
| CORE-BE-05 | Backend | Payments + ledger + webhook idempotency | Finance | P0 | Complete | `payment_webhook_events` migration; `webhook.integration.test.ts`, `finance.integration.test.ts` PASS |
| CORE-BE-06 | Backend | Redis / BullMQ queues | Backend | P1 | Partial | Redis connects in tests; queue depth/soak unproven |
| CORE-BE-07 | Backend | Strict TS build/typecheck | Backend | P1 | Partial | `tsconfig.json` present; build/typecheck not separately captured |
| LOGIN-01 | Login | Separate role login portals route to correct shell | Auth | P0 | Partial | `auth_portal.integration.test.js`, `auth.test.js` PASS; shell routing in `sero/lib/app` not E2E verified |
| LOGIN-02 | Login | Portal selection never grants role; backend authoritative | Auth/Sec | P0 | Partial | Backend tests present; frontend guard `widgets/shared/auth_guard.dart` exists |
| LOGIN-03 | Login | MFA/OTP/session rotation/revocation | Auth/Sec | P0 | Missing/Unverified | No MFA test evidence captured |
| SUPER-BE-01 | SuperAdmin | Society approval + platform control plane | SuperAdmin | P0 | Complete | `super_admin.ts`; `super_admin*.integration.test.ts` (3 suites) PASS; `create_platform_control_plane` migration |
| SUPER-FE-01 | SuperAdmin | Super Admin shell + 31 capabilities live | SuperAdmin | P1 | Partial | `providers/super_admin/` exists; live-data not screen-verified |
| STAFF-BE-01 | Staff | Staff/guard duties, attendance, parcels, visitors | Staff | P1 | Complete | `staff_pg.ts`,`guard_pg.ts`; `staff.integration.test.ts`,`staff_pack.integration.test.ts`,`guard.integration.test.ts` PASS |
| STAFF-FE-01 | Staff | Staff shell screens on live data | Staff | P1 | Partial | `providers/shared/staff_provider.dart`; screens not verified |
| RES-BE-01 | Resident | Resident features (complaints, visitors, payments, polls) | Resident | P1 | Complete | `resident_pg.ts`; `resident.integration.test.ts` PASS |
| RES-FE-01 | Resident | Resident shell on live data | Resident | P1 | Partial | screens present; not verified |
| AI-BE-01 | AI | Server-owned conversations, RAG, citations, guardrails | AI | P1 | Complete | `src/services/ai/*` (Chat/Guardrails/Prompt/Memory/Extraction); `ai_chat`,`ai_tool_authorization`,`ai_multilingual` tests PASS |
| AI-BE-02 | AI | Tool/action authorization (no permission bypass) | AI/Sec | P0 | Complete | `ai_tool_authorization.integration.test.ts` PASS |
| AI-FE-01 | AI | Copilot UI: stream/stop/regenerate/copy/feedback | AI | P2 | Partial | `screens/shared/ai_chat/*`, `services/ai_service.dart`; not E2E verified |
| AI-INNOV-01 | AI Innovation | Strategy: >=25 ranked ideas, stop before invasive impl | AI | P2 | Partial | `AIInnovationService.ts` + `ai_innovation.integration.test.ts` PASS; strategy doc deliverables not produced |
| CROSS-01 | QC | Cross-role journeys (visitor, complaint, payment, SOS...) | Cross | P0 | Missing | No E2E journey executed this pass |
| SEC-01 | QC/Login | IDOR/BOLA/mass-assignment/injection/SSRF | Security | P0 | Partial | Some negative tests; full sweep not done |
| SEC-02 | Backend | File/KYC security, private storage | Security | P1 | Complete | `file_security.integration.test.ts` PASS; `services/files` |
| PERF-01 | Load | 10K/20K user scale proven | Perf | P0 | Missing | No load run; `load/` + `stress_test.js` exist but not executed |
| PERF-02 | Load | Soak/stress/failure-injection/recovery | Perf | P1 | Missing | Not run |
| QC-01 | QC | Live data on every screen (no mock) | QC | P0 | **Failed** | 29 admin screens on `mock_data.dart`; `kUseMockData=true` |
| QC-02 | QC | Flutter analyze clean | QC | P1 | Partial | `flutter analyze` = 91 issues (49 warn, 42 info, **0 errors**) |
| QC-03 | QC | Backend test suite green | QC | P0 | Complete | `npm test` = 51 suites / 267 tests PASS |
| QC-04 | QC | Backup/restore evidence | QC | P0 | **Failed** | `backup_restore_smoke` SKIPS real dump (no pg_dump/DATABASE_URL) |
| RELEASE-01 | Release | Mocks/demo creds/localhost removed | Release | P0 | **Failed** | mock flag on, 29 screens, dev base URL `env.dart:5` |
| RELEASE-02 | Release | Secure signing (release != debug keys) | Release | P0 | **Failed** | `android/app/build.gradle.kts:38-39` release uses `signingConfigs.getByName("debug")` |
| RELEASE-03 | Release | App identity/version/icon/splash | Release | P2 | Partial | `pubspec.yaml:19` version 1.0.0+1; `applicationId/namespace = sero.com` |
| RELEASE-04 | Release | Signed APK/AAB installed + tested on device | Release | P0 | Missing | Not built/installed this pass |

## Coverage math (representative ledger, applicable rows)
- Rows: 33. Complete: 11. Partial: 13. Missing: 5. Failed: 4.
- **Verified ÷ total applicable = 11/33 ≈ 33%.**
- **P0 verified = 6/14 (CORE-BE-01,02,05; SUPER-BE-01; AI-BE-02; QC-03).** P0 Failed/Missing = QC-01, QC-04, CROSS-01, PERF-01, RELEASE-01/02/04, LOGIN-03(unverified).
- Section 13 rule: release cannot pass below 100% verified P0/P1 → **FAIL**.
