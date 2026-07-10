# Migration & Seed Status Report — 2026-07-10

## Migrations
- Mechanism: knex, run automatically on every Render deploy (`preDeployCommand: npx knex migrate:latest` in render.yaml) — deploys can't go live with pending migrations.
- Latest migration in repo: `20260707140000_parcels_domestic_help.js`. Live API serves `/parcels` and `/domestic-help` routes against their tables ⇒ production schema is current.
- Behavioral verification of table presence (all 200 on live): members-v2, notices(+audiences/reads), polls-v2, events-v2, funds/invoices/payments/allocations, complaints, amenities(+bookings), parking, notifications, visitors, parcels, domestic help, device tokens (migration 20260707100000).
- Direct `npx knex migrate:status` still recommended from Render Shell for an authoritative list (needs dashboard).

## Seeds (prod)
- Demo users live in **Firestore** (seeded via `hash_and_set.js`): `admin`/123456 (main_admin, demo-soc-1), `9876543200`/123456 (resident, demo-soc-1), `superadmin`/123456 (super_admin). All verified by live login.
- **Gap found (P1, fixed):** no Postgres seed mirrors Firestore memberships into `members` — resident_pg endpoints 403'd. Fixed by lazy self-provisioning in code (see DATABASE_CONNECTION_REPORT); a one-time backfill script is optional now.
- Postgres demo domain data (Hubtown Sunkist `9200000001` admin, units, invoices) exists on prod (funds/notices/polls return data).

## Table checklist vs prompt §4.3
Users/memberships ✅ (dual-store, self-heal added) · Societies ✅ · Units ✅ · Bills/invoices ✅ · Payments/receipts ✅ · Notices ✅ · Polls ✅ · Events ✅ · Visitors ✅ · Staff ✅ (table exists; no demo creds) · Complaints ✅ · Notifications ✅ · Device tokens ✅ · Parking ✅ · Amenities ✅ · Documents ✅ (rules-v2/documents route) · AI conversations ✅ (ai routes respond).
No endpoint hit a missing table (would surface as 500 relation-does-not-exist; none observed).
