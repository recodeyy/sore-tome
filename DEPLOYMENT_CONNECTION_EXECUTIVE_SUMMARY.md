# Deployment Connection — Executive Summary

> **Update (later 2026-07-10):** every defect below plus the superadmin-login issue is FIXED in commit `74361a5`
> (details: DEPLOYMENT_FIX_PLAN.md). Deploys pending owner approval: push tree to `render-live` (backend),
> `npm run sst:deploy` (website), `flutter build apk --release` (mobile). Gate: FINAL_DEPLOYMENT_RELEASE_GATE.md.

**Date:** 2026-07-10 · **Commit:** `139d2b7` · **Audit scope:** live production probes + repo config audit
(run from dev machine; Render/AWS dashboards and physical devices not accessed).

## Environments verified

| Component | Location | Status |
|---|---|---|
| Backend API | `https://sero-api-live.onrender.com` (Render, Docker, free plan) | ✅ Up, `/health` ok |
| Admin website | `https://d79huy0uhwumb.cloudfront.net` (SST → Lambda + CloudFront, eu-west-1) | ✅ Up, `/` and `/login` 200 |
| Website → backend link | BFF (`SERO_BACKEND_URL` SST secret) | ✅ Proxies to Render; backend errors surface correctly |
| Mobile release APK | `sero/lib/config/env.dart` default | ✅ Points to `https://sero-api-live.onrender.com/api/v1` (no localhost/GCP) |
| Auth store | Firebase / Firestore (project `sero-73976`) | ✅ Live login works; `firebaseToken` issued |
| Postgres (Render managed) | `sero-postgres`, migrated via `preDeployCommand` | ⚠️ Reachable, but demo data missing (see F-2) |
| Secrets in git | — | ✅ Only `.env.example` tracked; real `.env` files untracked |

## Live production test results (2026-07-10)

- `POST /api/v1/auth/login` with seeded resident (`9876543200`): **success** — `token` ✅, `firebaseToken` ✅, `activeWorkspace` ✅ (`demo-soc-1`, `resident_owner`, approved), `requiresWorkspaceSelection: false`.
- Post-login resident endpoints, all **200**: `/users/me`, `/notices-v2`, `/funds/summary`, `/funds/maintenance-status`, `/complaints`, `/amenities`, `/polls-v2`, `/events-v2`, `/notifications`, `/parking/my`, `/visitors`.
- Login contract consistent everywhere: backend expects `{phone, password, portal?}`; website BFF and both Flutter clients send exactly that.
- Legacy root mount (`/auth/login` without `/api/v1`) also live — the `kBaseUrl` strip in `auth_service.dart:11` is therefore harmless.

## Findings

### F-1 · P1 · Render free-tier cold start ≈ 50–60 s
- **Evidence:** first `GET /health` timed out at 60 s; immediate retry answered in <1 s.
- **Impact:** first app open / website login after a quiet period hangs or errors. Likely a major contributor to "blank screen after login" and empty-message connection errors.
- **Fix options:** paid Render instance (no sleep), an external pinger, and/or client-side: longer timeout + explicit "server waking up…" retry state in the Flutter app and website login.

### F-2 · P1 · Postgres-backed resident endpoints fail: "No active membership for this user" (403)
- **Evidence (production):** `/resident/family`, `/resident/vehicles`, `/resident/kyc`, `/resident/emergency-contacts` all return 403 for the demo resident.
- **Root cause:** dual data store. Auth/workspaces live in **Firestore** (`demo-soc-1` exists there), but `src/routes/resident_pg.ts` → `ResidentService.resolveContext` requires an approved row in the **Postgres `members` table** (`society_id + user_id + status='approved'`). No seed in the repo creates `demo-soc-1` members in Postgres, so the row doesn't exist on Render's DB.
- **Impact:** resident Profile / Family / Vehicles / KYC / Emergency sections show "Something went wrong" for any user whose membership exists only in Firestore. This matches the reported resident-section crashes.
- **Fix:** either seed/mirror memberships into Postgres for every approved Firestore workspace (backfill script + write-through on approval), or make `resolveContext` fall back to the Firestore membership.

### F-3 · P2 · Local `.env` points at a non-running Postgres (`localhost:5544`)
- Local backend dev needs `docker compose up -d` (or equivalent) in `society-backend/`; production is unaffected (Render injects its own `DATABASE_URL`). Explains local "connection error with empty message" shell output.

### F-4 · P2 · Live API keys in `sero-admin-web/.env.local` (untracked, but real)
- Groq, OpenAI, ElevenLabs keys and Razorpay **test** keys sit in plaintext local env files. Not in git (verified), but they are real credentials on a dev machine — rotate if this folder is ever shared/synced. Production uses SST Secrets (SSM), which is correct.

### F-5 · P3 · `render.yaml` sets `CORS_ORIGINS="*"` with `credentials: true`
- The custom origin callback compares literal strings, so `*` never actually matches a real origin — browser CORS to the API would fail. Currently moot (website goes server-side via BFF; mobile has no origin), but set it to the real website origin(s) to make direct browser calls possible and the config honest.

## Blocked (needs dashboards / physical devices)

- Render dashboard: deploy status, runtime logs, crash count, env-var presence (Firebase vars confirmed working indirectly — custom tokens are issued).
- Physical-device tests: FCM foreground/background/killed, blank-screen reproduction on device, two-phone sync suites (§7–9, §15 of the test prompt), `adb logcat` capture.
- Razorpay webhook delivery, receipt download, Society-B isolation with a second seeded society.

## Verdict

**PASS WITH EXCEPTIONS** for connectivity: deployed website ↔ backend ↔ database ↔ mobile-APK wiring is correct and live. **F-1 (cold start)** and **F-2 (Postgres membership gap)** are the two real defects to fix before calling the resident experience stable; device-side FCM/sync suites remain untested.
