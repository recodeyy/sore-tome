# SERO 10K–20K Load-Test Readiness Check

**Date:** 2026-06-16
**Scope:** Validation of the load-test suite and infrastructure prerequisites against
`SERO_10K_20K_Load_Test_Complete_Prompt_Pack.md`.

> **Verdict: NOT EXECUTED — environment-blocked.** A real 10K–20K run could not be
> performed in this environment (no k6 binary installed, no running/deployed backend).
> The prompt pack explicitly forbids claiming capacity without reproducible evidence,
> so **no PASS/FAIL capacity verdict is asserted.** This document reports what is
> *ready* and what *blocks* an actual run.

---

## A. Execution environment — why it could not run here

| Prerequisite | State |
|---|---|
| `k6` binary | **NOT installed** (`k6 version` → not found) |
| Backend reachable (`:4000/api/v1/health`) | **No server running** (curl → 000) |
| Deployed production-like staging (DB pooling, Redis, replicas) | **Not available** |
| Distributed / k6 Cloud runners for 10K–20K VUs | Not available |

Per the suite's own `load/README.md` and pack §7/§26, 10K–20K concurrent VUs +
equal long-lived SSE connections are **not feasible from a single host** (file-descriptor
/ ephemeral-port exhaustion; generator competes with app for CPU). A genuine run
requires k6 Cloud or distributed runners against deployed staging.

---

## B. Load-test suite inventory — PRESENT and mapped to the pack

`society-backend/load/` already implements the pack's staged plan:

| Script | Pack stage | Target |
|---|---|---|
| `k6_smoke.js` | Stage 0 sanity | 5 VUs / 30s health |
| `k6_load.js` | Stage 1 baseline | 0→500 ramp |
| `k6_scale.js` | core driver (`buildOptions`, `mixed`, `realtime`) | `-e TARGET=10k\|20k` |
| `k6_10k.js` | Stage 3 — Target A | 10k/5k active/600 RPS/1k burst/10k SSE |
| `k6_20k.js` | Stage 4 — Target B | 20k/10k active/1k RPS/1.5k burst/20k SSE |
| `k6_spike.js` | Stage 6 — burst | arrival-rate spike to `BURST_RPS` |
| `k6_soak.js` | Stage 5 — soak | held for `SOAK_HOURS` |

**Threshold assertions (match pack §21):** read p95 < 300 ms, write p95 < 500 ms,
mixed p99 < 1.5 s, `http_req_failed` & `business_errors` rate < 1%. Weighted mix
(~55% dashboard/finance reads, ~20% search, ~25% writes) + long-lived SSE scenario.
Verdict: **suite design is sound and faithful to the pack.**

---

## C. Findings — fixed during this check

The mixed-traffic driver targeted routes that do not exist, which would have
produced 404s on the dominant read path and silently corrupted the error-rate and
latency metrics (a false signal in either direction). Fixed in `load/k6_scale.js`:

| # | Was | Real route | Status |
|---|---|---|---|
| F1 | `GET /api/v1/admin/dashboard` (dominant read, ×2 per mixed iter) | `/api/v1/admin/dashboard/summary` | **FIXED** |
| F2 | `POST /api/v1/polls/vote` | `POST /api/v1/polls/:id/vote` (body `{option}`) | **FIXED** |
| F3 | README smoke pointed at `/api/v1/health` | health is top-level `/health` | **FIXED (doc note)** |

Without these, a run would have reported inflated `business_errors`/`http_req_failed`
on reads and a no-op (404) on the poll-vote hot-row write — invalidating the result.

---

## D. Infrastructure prerequisites — audit (static, code-level)

| Control (pack ref) | Present | Evidence | Note |
|---|---|---|---|
| Connection pooling (§9) | ✅ | `src/shared/Database.ts` `pg.Pool` | **`max: 10` per instance — see RISK below** |
| Distributed rate limiting (§7, §22) | ✅ | `middleware/rateLimiter.js` (Redis-backed, identity-aware, fail-open) | |
| Redis (cache/locks/sessions §10) | ✅ | `src/shared/Redis.ts` | |
| Idempotency (§13 payments) | ✅ | `FinanceService`, `RazorpayWebhookService`, `OutboxService` | webhook + outbox pattern present |
| Realtime SSE (§12) | ✅ | `src/routes/realtime.ts` (`text/event-stream`, tenant-scoped) | long-lived; needs distributed SSE client to soak |
| DB indexes (§9) | ✅ | 117 index declarations across `migrations/` | coverage not profiled under load |
| Health/readiness (§4) | ✅ | `/health`, `/health/deep` | |

---

## E. RISK flagged for a real run

- **DB pool `max: 10` per API instance (HIGH).** Pack §29 lists *connection-pool
  exhaustion* as an automatic FAIL. At 600–1,000 sustained RPS, 10 connections/instance
  means throughput is bounded by `(replicas × 10) / avg_query_seconds`. There is **no
  PgBouncer / external pooler** in the stack (pack §9 expects one). Before a Target A/B
  run: add PgBouncer (transaction pooling) or raise per-instance `max` with a sized
  Postgres `max_connections`, and watch pool-wait + `pg_stat_activity` saturation.
- **SSE soak needs a real streaming client.** k6's plain `http.get` on the SSE route
  (current `realtime()` fn) opens then holds for 15 s; a true 10K/20K connection soak
  needs k6's streaming/SSE support or a dedicated client, against deployed staging.

---

## F. To actually execute (the remaining work — needs infra, not code)

1. Deploy backend to production-like staging (replicas, sized Postgres + PgBouncer,
   Redis topology, object storage, observability).
2. Seed the pack §5 dataset (100–500 societies, 100k+ users, 1M+ events/payments).
3. Install k6; issue a valid scale `TOKEN` (or wire `auth_ramp` to mint tokens).
4. Run staged: smoke → baseline(500) → 3k → Target A(10k) → Target B(20k) → soak → stress → recovery,
   from k6 Cloud / distributed runners.
5. Capture the pack's 19 deliverable reports + run the §24 data-integrity invariants
   after each stage. Only then assert a PASS/FAIL capacity verdict.

---

## G. Summary

- **Suite:** present, well-structured, pack-faithful; **3 route bugs fixed** so a real run
  will produce valid metrics.
- **Infra controls:** pooling, Redis rate-limiting, idempotency, SSE, 117 indexes all present.
- **Top blocker for a valid run:** DB pool `max:10` with no external pooler — address before Target A/B.
- **Capacity claim:** **none made** — not executed; requires deployed staging + distributed k6.
