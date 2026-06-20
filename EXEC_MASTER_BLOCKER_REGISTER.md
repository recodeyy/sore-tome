# EXEC_MASTER_BLOCKER_REGISTER

Date 2026-06-16. Phase 0 baseline blockers. Distinct from the other agent's MASTER_BLOCKER_REGISTER.md
(this is the EXEC_ execution view; overlaps are noted).

## Baseline build/test results (Master §16.7)

| Check | Command | Result | Detail |
|-------|---------|--------|--------|
| Flutter analyze | `flutter analyze` in `sero/` | RAN — PASS (no errors) | 128 issues, all `warning`/`info` (unused imports, withOpacity deprecations, use_build_context_synchronously, unused locals). 0 compile errors. ran in 15.7s. |
| Backend tests | `npm test` in `society-backend/` | NOT RE-RUN this pass | Other agent's audit reports 51 suites / 267 tests PASS (41.5s). Not independently re-executed to respect the few-minutes baseline budget. Recorded as EXEC-BLK-05 (re-verify). |
| Flutter unit/widget tests | `flutter test` | NOT RUN | Deferred; budget. |

## Blocker register

| ID | Sev | Title | Evidence | Owner | Status |
|----|-----|-------|----------|-------|--------|
| EXEC-BLK-01 | P2 | 16 individual canonical FE/BE/QC prompt files missing; only packs exist | Master §1 vs repo Glob | Program | OPEN (mitigated: packs embed masters) |
| EXEC-BLK-02 | P2 | Product source files missing (SERO_Feature_List.pdf, AI Powered Society Managemen.txt); capability counts 31/32/57 unverifiable | repo Glob | Program | OPEN |
| EXEC-BLK-03 | P0 | Frontend on mock data: `sero/lib/config/dev_config.dart:1 kUseMockData=true`; ~29 admin screens import `data/mock_data.dart` and render zeroed static constants | dev_config.dart, MASTER_EXISTING_IMPLEMENTATION_AUDIT.md §2 | live-data agent | OPEN (do NOT edit this pass) |
| EXEC-BLK-04 | P1 | Dual data stack: legacy Firestore JS routes coexist with `_pg` TS routes; conflicts with "PostgreSQL source of truth" | society-backend/routes/*.js + src/routes/*_pg.ts | Backend | OPEN |
| EXEC-BLK-05 | P2 | Backend test suite not independently re-run this pass | budget | QA | OPEN |
| EXEC-BLK-06 | P0 | Backup/restore is a skipped smoke test, not real DR evidence | backup_restore_smoke.integration.test.ts (skips, pg_dump=false) | SRE | OPEN |
| EXEC-BLK-07 | P1 | No load test executed; 10K/20K scale unproven | MASTER_PERFORMANCE_CAPACITY_REPORT.md | SRE | OPEN |
| EXEC-BLK-08 | P0 | APK/AAB last release = FAIL gate (mock on, debug signing, cutover incomplete) | commit ea275e8 release report | Release | OPEN |
| EXEC-BLK-09 | P0 | API base URL dev-only (`http://10.0.2.2:3001`); no production endpoint configured | sero/lib/config/env.dart:5 | Mobile/DevOps | OPEN |
| EXEC-BLK-10 | P1 | 10 cross-role canonical-record journeys not executed end-to-end | Master §9 / QC §19 | QA | OPEN |
| EXEC-BLK-11 | P3 | 128 flutter analyze lint issues (warnings/info) | flutter analyze output | Mobile | OPEN (non-blocking; release gate forbids verbose/quality issues) |

## Top blockers (severity order)
1. EXEC-BLK-03 (P0) — mock cutover gates all FE verification + release.
2. EXEC-BLK-08 (P0) — APK release currently failing gate.
3. EXEC-BLK-06 (P0) — no real backup/restore evidence.
4. EXEC-BLK-09 (P0) — no production API config.
5. EXEC-BLK-04 (P1) — dual data stack must be reconciled.
