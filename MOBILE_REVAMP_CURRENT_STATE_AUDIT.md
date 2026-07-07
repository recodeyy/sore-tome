# MOBILE_REVAMP — Current State Audit

> Verified live on 2026-07-07 by running the stack locally (not from prior reports).
> Local commit `b3ab522` (2026-06-30) + 10 uncommitted fix files. **Local tree is NEWER than `origin/master`** (origin head `bd5d305`, 2026-06-21, is missing ~11k lines that exist locally; histories are unrelated — local repo was re-initialized). Do **not** `git pull`; push local state instead.

## 1. Verification method

- `flutter pub get` + `flutter analyze` → **0 errors**, 40 lints (info/warn only). App compiles.
- `npx tsc --noEmit` (backend) → **clean**.
- `docker compose -f society-backend/docker-compose.dev.yml up -d` → Postgres (pgvector/pg16, host **5544**) + Redis 7 up; `knex migrate:latest` → already up to date (42 migrations, ~151 tables).
- `npm start` → backend boots: Firebase ✅ Postgres ✅ Redis ✅ Outbox ✅; `GET /health` → 200.
- Live login + endpoint probes per role (see §3).
- `npx jest --ci` → **266/267 pass** on warm run (single failure: complaint staff-assignment uuid bug, see CRASH report). First cold run shows extra failures from parallel DB contention — not code bugs.

## 2. Architecture reality

| Layer | Reality |
|---|---|
| Mobile | Flutter 3.44.1, `sero/`, **310 Dart files**. Screens: admin 80, resident 36, shared 41, super_admin 19, guard 1(!), finance 1, rules 1. 69 named routes in `app.dart`. |
| Backend | Node 24 / Express, `society-backend/`. Legacy `routes/*.js` + canonical `src/routes/*.ts` (v2) both mounted under `/api/v1`. |
| Auth | Hybrid: identities+bcrypt in **Firestore `users`**; operational data in **Postgres**. Login = phone+password+portal. JWT now issued **scoped** (`society_id` present) — the 2026-06-25 "phantom workspace / unscoped-zeros" bug (FIND-001/002) is **fixed** in current code. Backend also returns a **Firebase custom token** so Firestore-backed screens authenticate (June-30 fix). |
| Realtime | Postgres outbox → OutboxPublisher → SSE (`/realtime/sse`). |
| Push | firebase-admin messaging exists server-side but **token registration is broken end-to-end** (see NOTIFICATION_GAP report). |
| Payments | Razorpay test key present in `.env` (`rzp_test_…`); `/funds/payments/create-order` + `/verify` routes exist. |

## 3. Live probe results (local backend, 2026-07-07)

Admin (`admin`/`123456`, portal=admin) — token scoped to `hubtown-sunmist`:

| Endpoint | Result |
|---|---|
| `/admin/dashboard/summary`, `/notices-v2`, `/complaints`, `/finance/invoices`, `/polls-v2`, `/events-v2`, `/amenities`, `/staff-v2`, `/visitors` | **200 with real data** |
| `/parking/allocations` | **404** — Flutter calls it, route missing/renamed (P1) |

Resident (`9876543200`/`123456`) — all 12 probed endpoints **200**: `/users/me`, `/notices-v2`, `/funds/maintenance-status`, `/finance/invoices`, `/complaints`, `/polls-v2`, `/amenities`, `/parking/my`, `/resident/family`, `/resident/vehicles`, `/visitors`, `/events-v2`.

Staff/Guard (`9000000001`/`123456`, portal=staff) — login **200**, role `guard`.
Super-admin login untested this run (rate-limiter window); credentials not in checklist doc.

## 4. Deployment reality (critical)

- **Only live backend = GCP Cloud Run** `https://sero-api-m477e5mida-el.a.run.app` (health 200, ~13 s cold start). This is the expiring environment, and it is the **default API_BASE_URL baked into release APKs** (`lib/config/env.dart`).
- Old Render service `sero-api.onrender.com` — subdomain **reclaimed by an unrelated app**; dead for SERO. `render.yaml` blueprint still in repo (free-plan api + postgres) and can be redeployed under a new name.
- Firebase project `sero-73976` (auth-adjacent + FCM) is independent of GCP billing for our compute; Firestore usage continues.

## 5. Verdict on §3 technology decision

**Stay on Flutter.** 0 analyzer errors, app builds, navigation works, all four role shells exist. No Expo migration justified.

## 6. Top gaps (ranked)

1. **Notifications broken end-to-end** — fcmToken never persisted (backend `PATCH /users/me` rejects it); NotificationService is a stub (no deep links, channels, background handling, multi-device). §10 fails today.
2. **Staff/Guard app is 1 screen** vs required 5-tab operational app (Gate/Tasks/Security…). Visitor/parcel/SOS staff flows minimal.
3. **No resident onboarding flow** (society search → wing/flat → admin approval → unlock). §5 fails today.
4. **Resident tabs** = Home/Community/Amenities/Payments/Profile vs spec Home/Community/**Pay(center)**/**Visitors**/More.
5. **Deployment cliff** — GCP expiring; only-live backend must migrate (plan in MOBILE_REVAMP_DEPLOYMENT_MIGRATION_PLAN.md).
6. `/parking/allocations` 404; complaint staff-assign 500 (uuid); legacy endpoints (`/funds`, `/issues`, `/rules`, `/channels`, `/notices`) still consumed in places.
7. Demo seed is `hubtown-sunmist` **A-1204**, prompt wants **Hubtown Sunkist A-1402**; seed lacks visitors/parcels/polls/amenity bookings/parking/vehicles depth.
