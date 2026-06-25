# MASTER_BLOCKER_REGISTER

Audit date: 2026-06-16. Ordered by release severity. Every blocker cites file/command evidence.

| # | ID | Severity | Title | Evidence (file:line / command) | Req IDs | Status |
|---|---|---|---|---|---|---|
| 1 | BLK-01 | P0 | Global mock flag ON | `sero/lib/config/dev_config.dart:1` `kUseMockData = true` (25 lib refs) | RELEASE-01, QC-01 | OPEN |
| 2 | BLK-02 | P0 | 29 admin screens render static mock data | screens import `sero/lib/data/mock_data.dart` (full list in MASTER_MOCK_STATIC_STUB_REPORT.md §2); e.g. `income_reports_screen.dart:56,62,129` | QC-01, RELEASE-01 | OPEN |
| 3 | BLK-03 | P0 | Release APK signed with DEBUG keys | `sero/android/app/build.gradle.kts:38-39` `signingConfig = signingConfigs.getByName("debug")` | RELEASE-02 | OPEN |
| 4 | BLK-04 | P0 | No signed APK/AAB built or device-tested | not performed this pass; prior commit `ea275e8` = FAIL gate | RELEASE-04 | OPEN |
| 5 | BLK-05 | P0 | Scale (10K/20K) unproven | no load run; `society-backend/load/`, `__tests__/stress_test.js` exist but not executed | PERF-01, PERF-02 | OPEN |
| 6 | BLK-06 | P0 | Backup/restore not proven | `__tests__/backup_restore_smoke.integration.test.ts:81` skips real dump (`pg_dump available=false, DATABASE_URL set=false`) | QC-04 | OPEN |
| 7 | BLK-07 | P0 | Cross-role E2E journeys not executed | Section 9 journeys (visitor/complaint/payment/SOS...) not run | CROSS-01 | OPEN |
| 8 | BLK-08 | P0 | Dev/localhost API base URL is default | `sero/lib/config/env.dart:5` `http://10.0.2.2:3001/api/v1`, `:10` localhost | RELEASE-01 | OPEN |
| 9 | BLK-09 | P1 | MFA/OTP/session rotation unverified | no test evidence captured for LOGIN-03 | LOGIN-03 | OPEN |
| 10 | BLK-10 | P1 | flutter analyze not clean | `flutter analyze` = 91 issues (49 warnings, 42 info, **0 errors**) | QC-02 | OPEN |
| 11 | SRC-BLOCK-01 | P2 | 16 individual canonical prompt files missing | see MASTER_PROMPT_FILE_INVENTORY.md §B1 | (coverage) | OPEN |
| 12 | SRC-BLOCK-02 | P2 | Product source PDF/TXT missing | see inventory §B2 | (coverage) | OPEN |
| 13 | BLK-11 | P3 | 31 TODO/FIXME, 8 Future.delayed in lib | grep counts over `sero/lib` | QC-01 | OPEN |

## Top remediation order
1. Flip `kUseMockData=false`, cut over the 29 screens to existing providers/services (plumbing already present).
2. Production config for API base URL (env injection).
3. Real keystore + release signing config.
4. Execute load suite; capture p50/p90/p95/p99 and highest verified capacity.
5. Real backup/restore drill with `pg_dump`/`DATABASE_URL`.
6. Automate Section 9 cross-role journeys.
7. Build + device-install signed APK/AAB; produce checksums.
