# MOBILE_REVAMP — Crash & Blank Screen Report

> Verified 2026-07-07. Historical crash classes vs current status.

## 1. Previously-reported classes and their CURRENT status

| Class | Root cause | Status now |
|---|---|---|
| Whole app replaced by "Something went wrong" | `GlobalErrorBoundary` swallowed framework errors app-wide | **Fixed** in commit `6b5634f` (2026-06-30) + uncommitted hardening in `widgets/shared/error_boundary.dart` |
| Firestore screens permission-denied → blank | App never signed into Firebase; backend JWT ≠ Firebase auth | **Fixed** `6b5634f`: backend issues Firebase custom token on login/restore; app signs in with it |
| Dashboards all zeros / lists empty | Unscoped JWT (`society_id=null`) after login when phantom `demo-soc-1` workspace forced selection | **Fixed**: login now returns JWT already scoped (verified live 2026-07-07) |
| Blank staff/guard screens; logout on restart | `/users/me` missing `society_id`/`role` | **Fixed** `6b5634f` + uncommitted `routes/users.js` change |
| Release APK dead on real phones | default API base was emulator URL | **Fixed**: default → Cloud Run (but see DEPLOYMENT plan — must move off GCP) |

## 2. Open crash/blank risks (found this audit)

| # | Sev | Where | Issue | Fix |
|---|---|---|---|---|
| C-01 | P1 | Admin parking | Flutter calls `GET /parking/allocations` → **404** → error state on parking screens | Align route (backend has different path; add alias or fix client) |
| C-02 | P1 | Complaints assign | `ComplaintService.assign` does `SELECT … FROM staff WHERE id=$1` with non-uuid id → pg throws → **500** (jest `complaint.integration` fails on exactly this) | Validate/lookup by `user_id` fallback; return 400 not 500 |
| C-03 | P2 | 12 screens | `use_build_context_synchronously` (analyzer): context used across async gaps in `society_logo_screen`, `impersonation_screen`, `kyc_verification_screen`, `feature_controls_screen`, `proposed_action_card` → setState-after-dispose class crashes | Add `mounted` guards |
| C-04 | P2 | `slot_allocation_screen.dart:95` | unnecessary/unsafe cast flagged | Remove cast, null-safe parse |
| C-05 | P2 | Cold-start network | Cloud Run cold start ~13 s > typical client timeout → first-open "network error" on release builds | Retry/backoff + skeleton, and new host without cold-start wall |
| C-06 | P3 | `app.dart` | 2 unused auth-screen imports (account_state, auth_challenge) suggest unreached account-state routes | Wire or remove |

## 3. §14 route-level guarantees — audit summary

- Loading/empty/error states: present on newer screens (June-30 work), **not uniform** across all 310 files. A shared `AsyncView` scaffold exists in parts; needs enforcement pass in Phase 4 (UI revamp) screen by screen.
- No global infinite-loader guard; SSE reconnect exists in `sse_manager.dart`.
- Unknown-enum fallback: models are hand-parsed; most use `?? default`, not verified exhaustively — Phase 2 adds tests for the top 20 models.

## 4. Verification protocol for closure

Each fix must be proven by: (a) unit/integration test, (b) live probe or app run, (c) entry in MOBILE_REVAMP_CRASH_FREE_REPORT.md with request-id evidence. Two-device cross-role session (§14) scheduled for Phase 7.
