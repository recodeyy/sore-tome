# DEPLOYMENT_FREE_LOW_COST_PLAN — SERO mobile backend off GCP

> 2026-07-07. Constraint: GCP is expiring. The only live backend today is Cloud Run
> `sero-api-m477e5mida-el.a.run.app` (also the default `API_BASE_URL` baked into shipped APKs, see `sero/lib/config/env.dart`).
> The old Render subdomain `sero-api.onrender.com` was **reclaimed by a third party — never reuse that hostname.**
> This plan covers the **mobile app backend**. The admin **website** has its own AWS plan (`WEBSITE_AWS_DEPLOYMENT_PLAN.md`).

## 1. Target stack (demo-grade, free/low-cost)

| Piece | Choice | Free-tier limit (verify at deploy) | Monthly cost at demo scale | Fallback |
|---|---|---|---|---|
| API compute | **Render web service** (docker, new name `sero-api-prod`) | 512 MB RAM, sleeps after 15 min idle (~50 s cold start), 750 hrs/mo | $0 (free) / $7 (starter, no sleep) | Railway hobby (~$5, no sleep), Fly.io shared-cpu-1x |
| Postgres | **Neon free** (pgvector supported) | 0.5 GB storage, 1 project, autosuspend | $0 | Supabase PG (0.5 GB), ⚠️ Render PG free **expires after 90 days** |
| Redis | **Upstash free** (serverless, TLS `rediss://`) | 256 MB, 500 K cmd/mo | $0 | Railway Redis. *Redis is optional — ioredis connects lazily; absence degrades to "caching disabled", not a boot failure.* |
| Files | keep **Firebase Storage** (project `sero-73976`) | 5 GB / 1 GB-day dl | $0 | Cloudflare R2 (10 GB free) |
| Auth / FCM / Firestore | keep **Firebase** (same project) | Spark plan generous for demo | $0 | — |
| APK distribution | **GitHub Releases** on `recodeyy/sore-tome` | unlimited public assets | $0 | Firebase App Distribution |
| Uptime pinger (anti-sleep) | cron-job.org hitting `/health` every 10 min | free | $0 | Render starter plan (no sleep) |

**Recommended demo config:** Render free + Neon free + Upstash free + Firebase = **$0/mo**.
**Recommended "always-warm" config** (for a live investor demo where the ~50 s cold start is unacceptable): Render starter $7 or Railway hobby ~$5 + Neon free + Upstash free = **~$5–7/mo**.

## 2. Why this split

- **DB not on Render**: Render's free Postgres is deleted after 90 days. Neon free has no such cliff → data survives.
- **Compute on Render**: `render.yaml` blueprint already exists at repo root with `preDeployCommand: npx knex migrate:latest` and a `/health` check — one-click Blueprint deploy.
- **Firebase kept**: identities, push (FCM), and Firestore live there and are independent of the expiring GCP *compute* billing. Moving them now adds risk for no benefit.

## 3. What must change in the app

`sero/lib/config/env.dart` reads `API_BASE_URL` from `--dart-define` and only falls back to the GCP URL. Two options:
- **Preferred:** change the `defaultValue` to the new Render URL and cut a new APK before GCP lapses.
- **Per-build:** `flutter build apk --release --dart-define=API_BASE_URL=https://sero-api-prod.onrender.com/api/v1`.

Old APKs already in the field point at Cloud Run and **will break when GCP lapses** — a new APK must be distributed before expiry (see runbook §7 rollback/forward).

## 4. Cost ceiling / scaling note

This plan is **demo-grade only** (Hubtown Sunkist + a handful of test users). For the 3k–20k-user load targets in the load-test prompt, none of these free tiers suffice — that requires the paid capacity plan (Railway/Render paid + Neon scale or RDS + Upstash paid), out of scope for this demo migration.

## 5. Secrets & security

No secrets in the repo. `.env` and the Firebase `*-adminsdk-*.json` stay untracked (confirmed gitignored). On Render, Firebase creds go in as `sync: false` env vars (`FIREBASE_PROJECT_ID/CLIENT_EMAIL/PRIVATE_KEY/STORAGE_BUCKET`) or a secret file. `JWT_SECRET` is `generateValue: true`. See `DEPLOYMENT_ENV_MATRIX.md`.

> ⚠️ Action item: the `sero-73976-firebase-adminsdk-*.json` currently sitting in the repo working directory is **not git-tracked** (verified) but should still be deleted from disk and the key **rotated** in the Firebase console as hygiene, since it was shared around.
