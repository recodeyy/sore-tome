# Load & Smoke Testing (k6)

These scripts exercise the backend with [k6](https://k6.io/).

## Install

```
# macOS
brew install k6
# Debian/Ubuntu
sudo apt-get install k6
# Windows
choco install k6
```

## Smoke test

Quick sanity check (5 VUs, 30s) against the health endpoint:

```
k6 run -e BASE_URL=http://localhost:4000 load/k6_smoke.js
# Note: health is served at top-level /health (not /api/v1/health).
```

## Load test

Staged ramp (0 -> 500 over 2m, hold 500 for 5m, ramp down). Hits a small mix
of read-only GET endpoints with a bearer token. Requires a valid JWT in `TOKEN`.

```
k6 run -e BASE_URL=http://localhost:4000 -e TOKEN=<jwt> load/k6_load.js
```

Thresholds enforced:
- `http_req_duration: p(95) < 300ms`
- `http_req_failed: rate < 0.01`

## 10K / 20K scale suite (SERO_10K_20K_Load_Test_Complete_Prompt_Pack)

These scripts implement the pack's staged plan against the real `/api/v1`
endpoint families discovered in `server.js` (dashboard, finance, notices,
complaints, events, polls, amenities, visitors, staff, reports, notifications,
realtime SSE).

Each stage runs: **ramp -> sustained -> burst -> ramp-down**, plus a long-lived
**SSE realtime** scenario. Traffic is a realistic weighted mix (~55% dashboard/
finance reads, ~20% search reads, ~25% writes: complaint create / poll vote).

| Script | Pack stage | Capacity target |
|--------|-----------|-----------------|
| `k6_10k.js` | Stage 3 — Target A | 10k auth / 5k active / 600 sustained / 1,000 burst RPS / 10k realtime |
| `k6_20k.js` | Stage 4 — Target B | 20k auth / 10k active / 1,000 sustained / 1,500 burst RPS / 20k realtime |
| `k6_spike.js` | Stage 6 — burst/spike | sudden arrival-rate spike to `BURST_RPS`, then recovery |
| `k6_soak.js` | Stage 5 — soak | steady mixed load held for `SOAK_HOURS` (4-8h) |
| `k6_scale.js` | parametrized core | `-e TARGET=10k|20k`; exports `buildOptions` + exec fns |

### Run commands

```
# Target A (10K)
k6 run -e BASE_URL=https://staging.api.example.com -e TOKEN=<jwt> load/k6_10k.js

# Target B (20K) — distributed/cloud runners only
k6 run -e BASE_URL=https://staging.api.example.com -e TOKEN=<jwt> load/k6_20k.js

# Parametrized
k6 run -e BASE_URL=... -e TOKEN=<jwt> -e TARGET=20k load/k6_scale.js

# Spike (model Target B's 1,500 RPS burst)
k6 run -e BASE_URL=... -e TOKEN=<jwt> -e BURST_RPS=1500 load/k6_spike.js

# Soak (4 hours)
k6 run -e BASE_URL=... -e TOKEN=<jwt> -e SOAK_HOURS=4 -e MAX_VUS=10000 load/k6_soak.js

# Dry-run on a laptop (validate behaviour, not capacity)
k6 run -e BASE_URL=http://localhost:4000 -e TOKEN=<jwt> \
  -e MAX_VUS=200 -e RT_VUS=200 -e BURST_RPS=100 load/k6_10k.js
```

### Self-authentication (no pre-issued TOKEN needed)

`k6_auth_ramp.js` implements the pack's `auth_ramp` scenario (login ramp +
session validation + refresh) **and** exports `mintToken()`. The scale/spike/soak
scripts now call it from k6 `setup()`: if you don't pass `-e TOKEN=<jwt>`, they log
in a seeded user and use that JWT automatically.

```
# Standalone auth ramp (Stage: login)
k6 run -e BASE_URL=https://staging.api.example.com \
  -e PHONE_PREFIX=+9190000 -e USER_COUNT=10000 -e PASSWORD=LoadTest@123 \
  load/k6_auth_ramp.js

# Scale run that self-authenticates (no TOKEN)
k6 run -e BASE_URL=https://staging.api.example.com \
  -e PHONE_PREFIX=+9190000 -e PASSWORD=LoadTest@123 load/k6_10k.js
```

Align `PHONE_PREFIX` / `USER_COUNT` / `PASSWORD` with your §5 seed command.
Auth thresholds (pack §7): login p95 < 1s, session p95 < 200ms, refresh p95 < 300ms.

### Env vars

- `BASE_URL` — target host (default `http://localhost:4000`).
- `TOKEN` — bearer JWT. Optional now; if omitted, scripts self-auth via `auth_ramp`.
- `TARGET` — `10k` or `20k` (k6_scale.js only).
- `PHONE_PREFIX`, `USER_COUNT`, `PHONE_PAD`, `PASSWORD`, `LOGIN_PHONE`, `PORTAL` — seeded-login config.
- `MAX_VUS`, `RT_VUS`, `BURST_RPS`, `SUSTAIN_MIN`, `SOAK_HOURS`, `LOGIN_RPS`, `BURST_LOGIN_RPS` — overrides.

### Connection pooling (addresses the readiness-check RISK)

The app pool is now env-tunable (`src/shared/Database.ts`): `DB_POOL_MAX`
(default 10), `DB_POOL_IDLE_MS`, `DB_POOL_CONN_TIMEOUT_MS`. `docker-compose.yml`
adds a **PgBouncer** (transaction mode) service. For 10K–20K runs put the API
behind PgBouncer (`DATABASE_URL=...@pgbouncer:6432/db`) and raise `DB_POOL_MAX`
(50–100) — PgBouncer caps real server connections via `DEFAULT_POOL_SIZE`.
Without a pooler keep `replicas × DB_POOL_MAX < Postgres max_connections`.

### Pass criteria (thresholds, from pack §21)

- Read p95 < 300 ms (`read_duration`)
- Write p95 < 500 ms (`write_duration`)
- p99 < 1.5 s for standard mixed APIs
- Error rate < 1% (`http_req_failed` and `business_errors`)

### Reaching 10K-20K VUs

Hitting 10,000-20,000 concurrent VUs (and an equal number of long-lived SSE
connections) is **not possible from a single laptop/CI box** — it exhausts file
descriptors and ephemeral ports, and the generator competes with the app for
CPU. Use **k6 Cloud** or **distributed k6** (multiple runners) against a deployed
staging environment with production-like DB pooling and Redis. Locally, use the
scaled-down dry-run command above to validate script correctness only.

## Notes

- A full 3k-concurrent-user / SSE soak test cannot be run reliably against a
  local dev box — it needs a deployed staging environment with production-like
  database, connection pooling, and a load generator that is not resource-bound
  by the app under test. Run the heavy soak from a dedicated k6 cloud / runner
  pointed at the deployed URL.
- The SSE gateway (`GET /api/v1/realtime/sse`) holds long-lived connections;
  soak-testing it requires k6's SSE/streaming support or a dedicated SSE client,
  again against a deployed environment.
