# Blank Screen After Login — Root Cause Report — 2026-07-10

## Reproduction (from live evidence, no device needed)
1. Backend idle >15 min on Render free plan → instance sleeps.
2. App opens / user logs in → every HTTP call has a **15-second timeout** (`api_client.dart _executeRequest`).
3. Cold start takes ~50–60s (measured: first `/health` >60s, warm 0.3s).
4. All initial requests throw `TimeoutException` → providers stay in error/loading → blank screen, infinite loader, or “Something went wrong”.

Second, independent cause for **resident sections** (Profile, Family, Vehicles, KYC, Emergency, Parcels, Domestic help, resident dashboard):
1. Login succeeds (Firestore-backed) with `activeWorkspace demo-soc-1`.
2. Screen calls `/api/v1/resident/*` → `ResidentService.resolveContext` finds no Postgres `members` row (memberships were Firestore-only) → 403 `No active membership for this user` (parcels: 500).
3. Screen error state → “Something went wrong”.

## Ruled out (checked live)
- Wrong API base URL (release APK → correct Render URL).
- `societyId: null` in login response (live login returns full activeWorkspace).
- Contract mismatch on login (phone/password matches everywhere).
- CORS (mobile sends no Origin; server allows origin-less requests).
- Auth token issues (JWT + refresh + firebaseToken all issued; refresh single-flight implemented).
- Missing tables (all core endpoints 200).

## Fixes (commit 74361a5)
| Cause | Fix | Verification |
|---|---|---|
| 15s timeout vs 60s cold start | ApiClient wake-and-retry (75s /health ping + 30s retry); website login retry with waking banner; GitHub Actions keepalive every 10 min | rebuild APK; after idle, first login should succeed in ≤90s worst case, instantly when keepalive holds the instance warm |
| Postgres membership missing | resolveContext self-heals membership from JWT society scope | `GET /resident/family` → 200 after backend deploy |

## Residual risks (P2, code-level hardening candidates)
- Providers that `throw` and never resolve loading state should still render retry UI — audit `AsyncValue.error` handling per screen on device.
- `!` on nullable model fields — run screen-level empty/null tests (needs device/emulator).
