# DEPLOYMENT_RUNBOOK — SERO mobile backend (GCP → Render + Neon + Upstash)

> Step-by-step with verification and rollback. Assumes repo `recodeyy/sore-tome`, `render.yaml` at root, migrations under `society-backend/migrations`.
> Time budget: ~45–60 min. Do the cutover with **Cloud Run still running** so rollback is instant.

## ✅ EXECUTION STATUS (2026-07-07) — data plane LIVE

| Piece | Status | Endpoint (masked) |
|---|---|---|
| **Neon Postgres** | ✅ **44 migrations applied + Hubtown Sunkist seeded (A-1402 verified)** | `…@ep-jolly-glade-atuguus9…aws.neon.tech/neondb` |
| **Upstash Redis** | ✅ **verified** (TLS PING=PONG, set/get ok) | `rediss://…@stirring-primate-89892.upstash.io:6379` |
| **Render API key** | ✅ verified — workspace `My Workspace` (`tea-…dl0`), 0 services yet | — |
| **Render web service** | ⏳ **1 step left** — see below | — |

**The only remaining step** is giving Render the *current* code. Render builds from a Git repo or a container registry; the GitHub token was excluded by the user, so use the **dashboard Blueprint** path (2 min): dashboard.render.com → New → **Blueprint** → connect the `recodeyy/sore-tome` GitHub repo → it reads `render.yaml`. Then in the service's **Environment** tab, set `DATABASE_URL` = the Neon string, `REDIS_URL` = the Upstash string, and paste the Firebase + Razorpay values (from `society-backend/.env`). The DB is already migrated+seeded, so `preDeployCommand` will just print "Already up to date". *(Prerequisite: push the current local branch to that GitHub repo so Render builds the revamp, not the stale `bd5d305` history — this needs your go-ahead on using Git, which is currently withheld.)*

## 0. Pre-flight

- [ ] `git check-ignore society-backend/.env sero-73976-firebase-adminsdk-*.json` → both print (ignored).
- [ ] You have: Firebase service-account values, Razorpay **test** keys, a GitHub account with repo access.
- [ ] Local suite green: `cd society-backend && npx jest --runInBand` (start server + seed logins for the 3 e2e_journeys login-smoke tests — see §5).

## 1. Provision Postgres (Neon)

1. Create Neon project (region closest to users, e.g. `ap-south-1`). Copy the pooled connection string.
2. Append `?sslmode=require`. This is `DATABASE_URL`.
3. Apply schema:
   ```bash
   cd society-backend
   DATABASE_URL='postgres://…@…neon.tech/neondb?sslmode=require' npx knex migrate:latest
   ```
4. **Verify:** `psql "$DATABASE_URL" -c "\dt"` shows `device_tokens`, `invoices`, `payments`, `receipts`, `demo_payment_audits`, etc.

## 2. Provision Redis (Upstash) — optional

1. Create Upstash Redis DB, copy the `rediss://` URL → `REDIS_URL`.
2. Skippable for demo; the app boots without it (caching disabled). Add later without redeploy downtime.

## 3. Deploy API (Render Blueprint)

1. dashboard.render.com → New → **Blueprint** → pick `recodeyy/sore-tome`. It reads `render.yaml`.
2. **Rename** the service to a unique name (e.g. `sero-api-prod`). *Do NOT use `sero-api.onrender.com` — reclaimed by a third party.*
3. Set dashboard env vars (`sync:false` ones): `FIREBASE_PROJECT_ID`, `FIREBASE_CLIENT_EMAIL`, `FIREBASE_PRIVATE_KEY` (keep literal `\n`), `FIREBASE_STORAGE_BUCKET`, `RAZORPAY_KEY_ID/SECRET/WEBHOOK_SECRET`, `ADMIN_DEMO_MODE=true`. Override `DATABASE_URL` to the **Neon** string (or drop the blueprint's managed PG and point at Neon). Optionally `REDIS_URL`.
4. Deploy. `preDeployCommand: npx knex migrate:latest` runs first (idempotent — already applied in §1, prints "Already up to date").
5. **Verify:** `curl https://sero-api-prod.onrender.com/health` → 200. (First hit ~50 s if free plan asleep.)

## 4. Seed demo data (Hubtown Sunkist A-1402)

```bash
cd society-backend
DATABASE_URL=<neon> node scripts/seed_hubtown_sunkist.js         # Postgres domain data (idempotent)
node scripts/seed_hubtown_sunkist_logins.js                       # Firestore login accounts
```
Logins: `9200000001` admin · `9200000002` resident · `9200000003` guard — password `123456`.
**Verify:** `psql "$DATABASE_URL" -c "SELECT number FROM units WHERE society_id='hubtown-sunkist' AND number='A-1402';"` returns 1 row.

## 5. Point the app at the new backend & build APK

```bash
cd sero
flutter build apk --release --dart-define=API_BASE_URL=https://sero-api-prod.onrender.com/api/v1
# → build/app/outputs/flutter-apk/app-release.apk
```
Or make it the default in `sero/lib/config/env.dart` (`apiBaseUrl` / `fallbackUrl`) and rebuild.

## 6. Two-device cross-role smoke (do before retiring GCP)

Install the new APK on two phones. Log in Admin on one, Resident on the other:
1. Admin publishes a notice → Resident gets push + sees it.
2. Admin generates a bill → Resident sees dues → pays via Razorpay **test** → receipt downloads.
3. Guard logs a Swiggy visitor for A-1402 → Resident approve card → Guard sees result + records entry/exit.
4. Resident raises a complaint → Admin assigns → Staff updates → Resident sees update.
Backend proof already automated: `bash society-backend/scripts/run_e2e_journeys.sh` (37 cross-role assertions + 3 login-smoke).

## 7. Cutover & rollback

- **Forward:** once §6 passes, publish the APK to **GitHub Releases** and let GCP Cloud Run lapse.
- **Anti-sleep (free plan):** add cron-job.org GET `/health` every 10 min, or upgrade to Render starter ($7).
- **Rollback (instant):** Cloud Run is still live during the window → rebuild/redistribute the APK with `--dart-define=API_BASE_URL=https://sero-api-m477e5mida-el.a.run.app/api/v1`, or flip `env.dart` default back. Because DB moved to Neon, also point `DATABASE_URL` back only if you rolled data; otherwise Cloud Run keeps its old DB (data divergence risk — prefer forward-fix).
- **DB rollback:** Neon branching lets you restore a pre-migration branch. Take a branch snapshot before §1 step 3.

## 8. Known limitations (demo)

- Free Render cold start ~50 s on first request after idle.
- Physical-device **push delivery** requires the production Firebase project's `google-services.json` in the APK (already present) and cannot be asserted from CI — validated in §6 two-device test only.
- Load beyond ~a few hundred concurrent users needs the paid capacity plan (out of scope here).
