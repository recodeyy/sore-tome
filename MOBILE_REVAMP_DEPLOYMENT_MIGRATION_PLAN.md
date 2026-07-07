# MOBILE_REVAMP — Deployment Migration Plan (GCP exit)

> 2026-07-07. Constraint: GCP is expiring; only live backend is Cloud Run `sero-api-m477e5mida-el.a.run.app` (also the default URL baked into shipped APKs). Old Render subdomain `sero-api.onrender.com` was **reclaimed by a third party** — never reuse that hostname.

## 1. Recommended target (demo-grade, free/low-cost)

| Piece | Choice | Why | Fallback |
|---|---|---|---|
| API | **Render web service** (new name, e.g. `sero-api-prod`) via existing `render.yaml` | Blueprint already written incl. `preDeployCommand: npx knex migrate:latest`; free plan OK for demo (sleeps; ~50 s cold start) | Railway (no sleep on hobby, ~$5), Fly.io |
| Postgres | **Neon free tier** (pgvector supported) | 0.5 GB, branching, no expiry cliff | Supabase PG, Render PG (90-day free limit ⚠️) |
| Redis | **Upstash free** | serverless, BullMQ-compatible (check maxRequestSize / eviction) | Railway Redis |
| Files | keep **Firebase Storage** (project `sero-73976`) | already wired; independent of expiring GCP compute billing | Cloudflare R2 |
| Auth/FCM/Firestore | keep **Firebase** | identities + push live there; no migration risk now | — |
| Admin website | AWS Amplify or S3+CloudFront (per separate website prompt) | static hosting cheap | Vercel |
| APK distribution | **GitHub Releases** on `recodeyy/sore-tome` | zero cost, links shareable | Firebase App Distribution |

## 2. Migration steps (runbook summary)

1. Provision Neon DB → set `DATABASE_URL`; run `npx knex migrate:latest`; run seed (`scripts/seed_hubtown_sunmist.js` after Phase-6 upgrade).
2. Provision Upstash → `REDIS_URL` (TLS `rediss://`).
3. Create Render service from repo (new unique name); env vars from `DEPLOYMENT_ENV_MATRIX.md`; secret files: Firebase service account via Render secret file.
4. Data migration from Cloud Run's current PG: `pg_dump` → restore into Neon (verify row counts on key tables: members, invoices, complaints, notices, visitors).
5. Flutter `lib/config/env.dart`: default `API_BASE_URL` → new Render URL. Build APK, upload to GitHub Release.
6. Keep Cloud Run running in parallel until new URL verified (two-device test), then let GCP lapse.
7. FCM/Firestore unaffected (same Firebase project).

## 3. Risks

- **Free-tier sleep** (Render): first request ~50 s. Mitigation: uptime pinger (cron-job.org every 10 min) or Railway hobby.
- **SSE on free tiers**: long-lived connections may be dropped; app's `sse_manager` must auto-reconnect (verify Phase 7).
- **Old APKs** point at Cloud Run URL → will die when GCP lapses. Force-update path: release new APK before expiry; optionally keep a tiny redirect proxy if any grace budget remains.
- Render PG free expires after 90 days — that's why DB goes to Neon, not Render.

## 4. Deliverables (Phase 8)

`DEPLOYMENT_FREE_LOW_COST_PLAN.md` (expanded costs/limits), `DEPLOYMENT_ENV_MATRIX.md` (var × environment), `DEPLOYMENT_RUNBOOK.md` (step-by-step with rollback). No secrets in repo — `serviceAccountKey.json` and `.env` stay untracked (verify .gitignore; the firebase adminsdk json sitting in repo root **must be removed/rotated** ⚠️).
