# SERO Backend — Phase 0 Audit

**Date:** 2026-06-15
**Scope:** `society-backend/` (Node/Express) and its integration with `sero/` (Flutter).
**Method:** Static inspection with file/line evidence. Runtime reproduction (install/build/test/load) is **not yet performed** — see "Not yet verified" at the end. Findings below are evidence-backed reads, not runtime proofs.

---

## 1. Existing architecture (as-is)

| Concern | Reality in repo | Evidence |
|---|---|---|
| HTTP framework | Express 4, single process | `server.js` |
| Language | **Mixed JS + TS**, run via `tsx` (no compile step) | `package.json:7` `"start": "tsx server.js"`; `routes/*.js` + `src/**/*.ts` |
| Identity | **Custom JWT** signed with `JWT_SECRET` + bcrypt passwords. **No Firebase ID-token verification anywhere.** | `middleware/auth.js:16` `jwt.verify(token, JWT_SECRET)`; `grep verifyIdToken` → 0 hits |
| System of record (business data) | **Firestore** for funds, notices, issues, visitors, polls, channels, etc. | `routes/funds.js:3,16`; all `routes/*.js` use `getDb()` (Firestore) |
| System of record (AI/audit) | **PostgreSQL** (Knex) — AI tables + partitioned audit logs only | `migrations/` (4 files, all AI/audit) |
| Cache / locks / queues | Redis (ioredis), Redlock, BullMQ present | `package.json`; `src/shared/Redis.ts`, `LockService.ts` |
| Payments | Razorpay provider + PaymentService (TS) | `src/services/payment/*` |
| AI/RAG | Extensive TS subsystem (chat, extraction, vector store, guardrails, cost) | `src/services/ai/*` |
| Realtime | **None server-side.** No WebSocket/SSE. Flutter reads Firestore directly. | no ws/sse server code; `providers/shared/presence_provider.dart` |
| Observability | Pino logger, Sentry, request-context middleware | `src/shared/Logger.ts`, `server.js:14`, `middleware/ContextMiddleware.js` |
| Deployment | Single Dockerfile + minimal docker-compose | `Dockerfile`, `docker-compose.yml` |

**Summary:** This is a **Firestore-backed app with a thin custom-JWT Express API and a sophisticated bolt-on AI subsystem in TypeScript.** The prompt's target architecture (PostgreSQL as authoritative source of truth, Firebase Auth identity, double-entry ledger, RLS, outbox-driven realtime) is **largely not implemented** — it exists only for the AI/audit slice.

---

## 2. Working / partially working / missing

**Working (real endpoints, tenant-filtered Firestore):** auth login/JWT, users, notices, issues, funds (basic), rules, events, visitors, staff, facilities, polls, channels, admin dashboard, admin access logs, AI chat. Tenant filtering is applied via `tenantMiddleware` on most routes.

**Partial / not production-grade:**
- Finance: single `transactions` collection, no invoices/ledger/journal, amounts as floats, in-memory pagination capped at 100–500 docs.
- RBAC: hard-coded role checks in `middleware/auth.js`; no roles/permissions tables.
- Payments: Razorpay TS service exists but is not wired into a Firestore/Postgres-consistent flow.

**Missing entirely vs. the 92-capability spec:** billing runs, invoices, double-entry ledger, expense approval workflow, bank reconciliation, GST invoicing, committee/KYC lifecycle, structured wings/blocks/floors/units, SLA engine, staff payroll/attendance/roster, amenity booking engine with locking, parking/asset registries, scheduled reports, RLS, outbox/realtime gateway, OpenAPI spec, k6 load suite.

---

## 3. Security & scale risks (prioritized)

### P0 — committed secrets
- `sero-73976-firebase-adminsdk-fbsvc-d64fc169d7.json` (repo root) — **Firebase admin private key in git.**
- `society-backend/config/serviceAccountKey.json` — **second service-account key in git.**
- `society-backend/.env` — committed env (contains real values).
- **Impact:** full Firebase project compromise. **Action:** rotate keys, purge from history, gitignore. (Requires git-history rewrite — owner decision needed.)

### P0/P1 — identity & authorization
- **Firestore rules allow any same-society authenticated user to create/update/delete ANY collection** including financial data — no role check on the generic match. `firestore.rules:17-33`. The Flutter client holds Firestore access, so a resident can write `transactions`/`funds` directly. (Known issue #9 confirmed.)
- **API auth and Firestore rules use two different identities.** API = custom JWT (`auth.js:16`); Firestore rules trust `request.auth.token.society_id`/`role` (Firebase Auth custom claims). These are not the same token system → rules may not be enforceable as intended.
- **Role naming inconsistent:** `auth.js` uses `superadmin`, `main_admin`, `treasurer`, `secretary`; rules check `['admin','main_admin']`; prompt expects `super_admin`. (Known issue #19 confirmed.)

### P1 — rate limiting / CORS / routing
- **Auth limiter mounted on the wrong path.** `server.js:85-86` applies `authLimiter` to `/auth/login` and `/auth/register`, but real routes live at `/api/v1/auth/...`. The limiter never fires for the canonical path. (Known issue #6 confirmed.)
- **Rate limiting is in-memory** (`express-rate-limit` default store), so it is per-process and resets on restart / is bypassable across replicas, despite Redis being available. (Known issue #7 confirmed.)
- **CORS env var mismatch.** Code reads `process.env.CORS_ORIGINS` (`server.js:89`) but `.env.example` documents `ALLOWED_ORIGINS`. (Known issue #8 confirmed.)
- **CORS open in development AND when NODE_ENV unset.** `server.js:94` allows all origins if `NODE_ENV === 'development'`; `.env.example` ships `NODE_ENV=development`.
- **Legacy unversioned routes mounted at `/`.** `server.js:129-138` re-mounts the full v1 router at root, so every endpoint is reachable without `/api/v1` and partly outside the intended limiter scoping. (Known issue #15/#8 confirmed.)

### P1/P2 — data integrity & scale
- **No PostgreSQL for business data; no RLS.** Migrations cover only AI/audit tables. Tenant isolation depends entirely on app-level `.where('society_id','==',...)` filters with no defense in depth. (Known issue #14/#16 confirmed.)
- **Finance uses floats and capped reads.** `routes/funds.js:88` `Number(amount)`; `:18,:51` `.limit(100)/.limit(500)` then in-memory sort. Balances computed from a truncated window are wrong at scale. (Known issue #13 confirmed.)
- **DB pool max = 10** (`knexfile.js:12,27`) — cannot serve 3,000 users.
- **Production DB SSL `rejectUnauthorized: false`** (`knexfile.js:23`) — MITM exposure.
- **Cron jobs init unconditionally in-process** (`server.js:56-59`) — will run on every replica (no leader election). (Known issue #15 confirmed.)
- **Cursor pagination is fake** — fetches up to 500 docs then slices in memory (`routes/funds.js:62-70`); cursor is an in-window id, not a tenant-safe DB cursor.

---

## 4. Frontend mock / direct-Firestore inventory (to expand in Phase 0 completion)

- Flutter reads Firestore directly for presence/channels (`sero/lib/providers/shared/presence_provider.dart`, `channels_provider.dart`).
- Many admin screens reference models with `.fromJson`; a full screen-by-screen mock inventory is the remaining Phase 0 deliverable (`FRONTEND_BACKEND_CONTRACT.md`).

---

## 5. Not yet verified (requires runtime — next Phase 0 steps)

These are claimed by the prompt and must be **proven by execution**, not assumed:
- `npm ci` clean install (LangChain/Stagehand/Zod peer conflict; `canvas` native build on Windows).
- `jest` pass/fail + open handles.
- TypeScript strict compile (note: `package.json` runs via `tsx` with **no build/typecheck gate**).
- Docker build / compose up / migrations from empty DB.

---

## 6. Decision points blocking implementation

Phase 1+ cannot proceed coherently until three forks are chosen (see conversation):
1. **Identity:** keep custom JWT, or migrate to Firebase Auth ID-token verification (prompt's mandate)?
2. **Data store:** keep Firestore as source of truth, or migrate business data to PostgreSQL + RLS (prompt's mandate; the bulk of the work)?
3. **Secrets:** authorize git-history purge + key rotation now?

---

## 7. Fixes applied this session (Phase 1, batch 1)

Small, isolated hardening that's correct under the chosen architecture and does not touch the running app:

- **Distributed rate limiting** — new `middleware/rateLimiter.js` (Redis-backed, identity-aware, fails open). Replaces the in-memory `express-rate-limit` limiters in `server.js`. Keys by user when authenticated, IP otherwise, so shared-NAT residents aren't collectively blocked.
- **Auth limiter mount-path bug** — limiter now sits on `/auth/login` and `/auth/register` *inside* `v1Router`, so it covers both `/api/v1/auth/*` and the legacy `/` mount. (`server.js`)
- **CORS env var** — now reads `CORS_ORIGINS` **or** `ALLOWED_ORIGINS`, ending the mismatch with `.env.example`. (`server.js`)
- **DB pool / SSL** — pool max raised to 20 (`DB_POOL_MAX` override); production SSL now verifies the server cert unless `DB_SSL_REJECT_UNAUTHORIZED=false`. (`knexfile.js`)
- **Firestore rules** — privileged collections (finance + governance config) now require an admin role to write; `society_settings` write gated to admins. (`firestore.rules`) — *file only; takes effect on next `firebase deploy`.*

Decisions captured in `ARCHITECTURE_DECISIONS.md` (ADR-001 hybrid data store, ADR-002 Firebase Auth, ADR-003 secrets deferred).

> Note: `routes/channels.js` and `routes/notices.js` keep their own per-route `express-rate-limit` instances; left as-is to avoid churn — they still function.

## 8. Foundation verification results (executed)

| Gate | Command | Result |
|---|---|---|
| Clean install | `npm ci` | **PASS** (exit 0, no `--force`/`--legacy-peer-deps`). Was failing with `ERESOLVE`; fixed by removing `@langchain/community` (only used for `PGVectorStore`, replaced with direct SQL insert) and adding the directly-imported `@langchain/textsplitters`. `canvas` native build succeeded on Windows. |
| Tests | `npx jest` | **PASS** — 6/6 suites, 19/19 tests. Notice role-permission failures (issue #3) fixed by widening `canManageContent`/`adminOnly` to the canonical admin tier. |
| Boot | `npm start` + `GET /health` | **PASS** — server boots, Firebase connects, `/health` → 200. |
| Node pin | — | Added `engines.node: ">=22 <25"`. |

**Still open (non-blocking):** 48 npm-audit vulns (1 critical `protobufjs`, 6 high) — most have `npm audit fix` available; Jest still force-exits (open handles, issue #4) — masked by `forceExit: true`; migrations-from-empty-DB not yet run (no local Postgres) — `document_chunks`/`fts_content` have no creating migration (LangChain created them at runtime), to be addressed in the finance/migration phase.

## 9. Phase 3 — Finance core (built & verified)

Postgres-backed finance with a real double-entry ledger, verified against the dev Postgres container.

- **Schema** `migrations/20260616120000_create_finance_core.js` — `chart_of_accounts`, `invoices`, `invoice_lines`, `payments`, `payment_allocations`, `journal_entries`, `journal_lines`. Money in integer minor units; `journal_lines_one_sided` CHECK enforces one-sided, non-negative lines (DB-verified to reject a two-sided line).
- **Service** `src/services/finance/FinanceService.ts` — `createInvoice` (totals derived server-side), `publishInvoice` (posts balanced Dr A/R / Cr Income in one transaction; immutable + idempotent on re-publish), `recordPayment` (idempotency-keyed, posts Dr Cash / Cr A/R), reads. Standard accounts auto-created per society.
- **API** `src/routes/finance.ts` → `/api/v1/finance/*`, Zod-validated, RBAC via `canManageFunds`.
- **Tests** `__tests__/finance.integration.test.ts` (real Postgres): balanced ledger after publish; payment recorded exactly once under a repeated idempotency key. Full suite now **21/21 green**.
- **Bug caught by the test:** pg returns `bigint` as strings → journal sums were string-concatenating; fixed with `Number()` coercion in `postJournal`.
- Also fixed: DB heartbeat timer now `.unref()`'d (fewer Jest open handles), and the empty-DB migration gap (`document_chunks`/`semantic_cache` now have a creating migration; list made order-tolerant).

**Dev stack:** `docker-compose.dev.yml` (Postgres+pgvector on host **5544**, Redis on 6379). `.env` `DATABASE_URL` points at it.

**Flutter (done):** `Invoice` model, `invoicesProvider`, and an `INVOICES` tab in the existing funds screen call `/finance/*` via the authenticated `ApiClient`. `dart analyze` clean.

## 10. Phase 3 — Expense approval (maker-checker, built & verified)

- **Schema** `migrations/20260616130000_create_expenses.js` — `expenses` (status pending_approval/approved/rejected, links `journal_entry_id`) + `expense_approvals`.
- **Shared ledger** extracted to `src/services/finance/ledger.ts` (`withTx`, `ensureAccount`, `postJournal`); `FinanceService` now imports it (DRY).
- **Service** `src/services/finance/ExpenseService.ts` — `createExpense` (pending), `decide` (approve/reject). Maker-checker: the creator cannot approve their own expense (`MAKER_CHECKER` → 403). Approval posts Dr Operating Expense / Cr Cash in one transaction and stamps `journal_entry_id`.
- **API** `/api/v1/finance/expenses`, `/expenses/:id/decision` (Zod + `canManageFunds`).
- **Tests** `__tests__/expense.integration.test.ts` (real Postgres): self-approval rejected with no ledger movement; cross-approver approval posts a balanced entry. **Full suite now 23/23 green across 8 suites.**

## 11. Phase 3 — Razorpay webhook (built & verified)

- **Schema** `migrations/20260616140000_create_payment_webhook_events.js` — stores every event (unique `(provider, event_id)`) for replay protection + audit.
- **Service** `src/services/payment/RazorpayWebhookService.ts` — verifies HMAC-SHA256 over the **raw body** against `RAZORPAY_WEBHOOK_SECRET` (`timingSafeEqual`), stores the event once (duplicate deliveries ignored), and on `payment.captured` posts to the ledger via `FinanceService.recordPayment` keyed `rzp:<paymentId>` — exactly-once even though delivery is at-least-once (double protection: event dedup + payment idempotency key).
- **Route** `POST /api/v1/finance/webhook/razorpay` — public, signature-verified; returns 200 on valid (so Razorpay stops retrying), 400 on bad signature. Path contains `/webhook` so `server.js` captures `req.rawBody`.
- **Tests** `__tests__/webhook.integration.test.ts` (real Postgres): bad signature → rejected; captured payment processed once; duplicate delivery ignored; ledger balanced. Live boot smoke: no-signature POST → **400**.
- **Full suite: 25/25 green across 9 suites.**

## 12. Phase 3 — Finance reports (built & verified)

- **Service** `src/services/finance/FinanceReportService.ts` — `summary` (invoiced/collected/outstanding/expenses), `trialBalance` (per-account debit/credit + `balanced` flag), `dues` (outstanding published invoices with 0-30/31-60/61-90/90+ ageing buckets).
- **API** `GET /finance/reports/summary | trial-balance | dues` (auth + tenant).
- **Test** `__tests__/finance-report.integration.test.ts`: with 2 invoices (100k), one 30k payment, one 20k approved expense → summary math exact, **trial balance balanced**, dues 70k across 2 invoices.
- **Full suite: 26/26 green across 10 suites.**

### Finance subsystem status (Phase 3 substantially complete)
Billing → publish → immutable double-entry ledger → idempotent payments → expense maker-checker → Razorpay webhook (raw-body verified, exactly-once) → reports (summary/trial-balance/dues). All money float-free in minor units; all flows covered by integration tests against real Postgres. Flutter wired for invoices (create/publish/pay).

## Appendix — confirmed vs. the prompt's "known issues" (§19)

| # | Known issue | Status |
|---|---|---|
| 1 | LangChain/Stagehand/Zod peer conflict | Not yet run (deps present) |
| 2 | `canvas` native build | Not yet run (dep present `package.json:26`) |
| 3 | Notice test role expectations | Not yet run |
| 4 | Jest open handles | Not yet run |
| 5 | Mixed JS/TS | **Confirmed** |
| 6 | Auth limiter mount-path bypass | **Confirmed** `server.js:85-86` |
| 7 | Process-local rate limiting | **Confirmed** |
| 8 | CORS env var naming | **Confirmed** `server.js:89` vs `.env.example` |
| 9 | Firestore rules allow same-tenant writes w/o role | **Confirmed** `firestore.rules:17-33` |
| 10 | Admin service stubs | Partially confirmed (finance/payment thin) |
| 11 | Screens use mock data | Pending full inventory |
| 12 | Frontend writes Firestore directly | **Confirmed** (presence/channels providers) |
| 13 | Finance from arbitrary recent-tx limit | **Confirmed** `routes/funds.js:18,51` |
| 14 | Schema covers mainly AI tables | **Confirmed** `migrations/` |
| 15 | Legacy unversioned routes reachable | **Confirmed** `server.js:129-138` |
| 16 | Load script doesn't prove capacity | Pending (`__tests__/stress_test.js` to review) |
