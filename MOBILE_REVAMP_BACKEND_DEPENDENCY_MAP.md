# MOBILE_REVAMP — Backend Dependency Map

> 2026-07-07. What the mobile app depends on, and where each capability lives.

## 1. Services & stores

| Dependency | Tech | Used for | Migration note (GCP exit) |
|---|---|---|---|
| API | Node 24/Express (`society-backend`), TS `src/` + legacy JS `routes/` | everything | container-ready (Dockerfile); portable |
| Postgres | pgvector/pg16, 42 migrations, ~151 tables, RLS + tenant middleware | canonical operational/financial data | → Neon/Supabase/Railway PG (needs pgvector) |
| Firestore (`sero-73976`) | Firebase | **auth identities + bcrypt passwords**, some notifications, chat | Firebase is billing-independent of expiring GCP compute — keep initially |
| FCM | firebase-admin | push (broken at token-registration, see gap report) | keep |
| Redis | Redis 7 | BullMQ queues, workers (complaint escalation, cleanup), cache | → Upstash/Railway Redis |
| SSE realtime | outbox table → OutboxPublisher → `/realtime/sse` | live updates in app | portable, needs sticky/long-lived connections on new host |
| Razorpay | test keys in `.env` | payment demo | portable |
| AI | Anthropic/Groq/Cerebras via langchain, RAG (pgvector) | `/ai/*` chat, digest, extract | portable, keys via env |
| Storage | Firebase Storage bucket | images/attachments | → R2/Supabase Storage later; keep initially |

## 2. Route surface consumed by mobile (116 paths)

Canonical (TS `src/routes`): `/admin/dashboard/*`, `/members-v2`, `/structure/*`, `/finance/*`, `/complaints`, `/staff-v2/*`, `/parking/*`, `/amenities`, `/assets*`, `/reports/*`, `/notices-v2`, `/polls-v2`, `/events-v2`, `/rules-v2`, `/community*`, `/guard/*`, `/resident/*`, `/security/*`, `/super-admin/*`, `/realtime/sse`, `/ai/*`.

Legacy (JS `routes/`) still consumed: `/auth/*` (login/refresh/workspace), `/users/*` (me/profile), `/funds/*` (Razorpay + maintenance status), `/visitors*`, `/notifications`, `/channels`, `/rules`, `/issues`, `/polls/{id}/vote`, `/meetings`.

Legacy is not "dead" — auth, users, funds, visitors are legacy-only. Unification target (Phase 2): keep mounted, fix mismatches, migrate opportunistically; do not break shipped APK contracts.

## 3. Known contract mismatches (Phase 2 fix list)

1. `GET /parking/allocations` — app calls, backend 404s (route exists under different path/mount).
2. `PATCH /users/me` — drops `fcmToken` (P0, notification chain).
3. Complaint staff-assign — non-uuid staff id → 500.
4. Poll voting — one app path uses legacy `/polls/{id}/vote` while reads use `/polls-v2`.
5. Missing: resident join-request (onboarding), visitor pre-approval pass QR/OTP endpoints, parcels, SOS resident-trigger, domestic-help profiles (verify per module during Phase 2).

## 4. Boot & env

`.env` requires: `DATABASE_URL` (localhost:5544 dev), `REDIS_URL`, `FIREBASE_SERVICE_ACCOUNT_PATH` (`config/serviceAccountKey.json` — **secret, never commit**), `RAZORPAY_KEY_ID/SECRET` (test), `JWT_SECRET`, AI keys. Health: `GET /health`. Migrations: `npx knex migrate:latest` (pre-deploy hook in render.yaml).
