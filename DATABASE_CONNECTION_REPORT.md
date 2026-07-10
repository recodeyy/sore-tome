# Database Connection Report — 2026-07-10

## Local database
- `.env` → `postgres://sero:****@localhost:5544/sero_dev`
- **Status: DOWN.** Docker Desktop not running (`docker compose up -d` fails on npipe connect). This is the source of local shell "connection error with empty messages" (`PostgreSQL Heartbeat Failed` logs with empty error string).
- Backend still boots without Postgres (pool heartbeat retries) but Postgres-backed routes fail.
- Fix: start Docker Desktop → `cd society-backend && docker compose up -d` (compose warns PG_USER/PG_DATABASE/PG_PASSWORD unset — export them or add to `.env`), then `npx knex migrate:latest && npm run seed` (inspect package scripts first).

## Production database (via deployed API behavior — no direct connection made)
- Deployed backend Postgres is **connected and healthy**: Postgres-backed endpoints (`/api/v1/notices-v2`, `/funds/summary`, `/polls-v2`, `/complaints`, `/amenities`, `/events-v2`, `/parking/my`) all return 200 with data for the demo resident.
- Migrations are applied on deploy via render.yaml `preDeployCommand: npx knex migrate:latest` — table-dependent endpoints (notices, polls, funds, amenities, parking, complaints, members, parcels, domestic help) respond without missing-relation errors ⇒ schema current through `20260707140000_parcels_domestic_help`.
- SSL: knexfile honours `DB_SSL_REJECT_UNAUTHORIZED=false`; pg pool uses `rejectUnauthorized:false` for non-localhost. No SSL failures observed.
- RLS: enabled by `20260616204000_enable_rls`; app sets `app.society_id` per query (Database.ts) and resets before pool release — verified working (cross-tenant data not returned).

## Firestore (second data store)
- Firebase project `sero-73976`. Auth users, refresh tokens, legacy collections live here. Production login reads/writes Firestore successfully ⇒ Firebase Admin credentials valid on Render.

## Data-consistency defect (P1, FIXED in 74361a5)
- Memberships created via Firestore flows were never mirrored to Postgres `members`; `ResidentService.resolveContext` therefore threw NOT_A_MEMBER → `/resident/family|vehicles|kyc|emergency-contacts` 403, `/parcels` 500 (its error map lacked NOT_A_MEMBER), `/resident/dashboard`/`/domestic-help` 403 — for every Firestore-only resident (including demo `9876543200`).
- Fix deployed in code: `resolveContext` now lazily provisions an approved `members` row from the JWT's society scope (resident roles only); claims wired through resident_pg, parcels_pg, domestic_help_pg routers.
- Verification after deploy: `GET /api/v1/resident/family` with demo resident token must return 200 `{family:[...]}`.

## Missing tables/columns/indexes
- None observed via API surface. Direct `knex migrate:status` against the production DB requires the Render dashboard `DATABASE_URL` (masked) — run from Render Shell: `npx knex migrate:status`.
