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

## Notes

- A full 3k-concurrent-user / SSE soak test cannot be run reliably against a
  local dev box — it needs a deployed staging environment with production-like
  database, connection pooling, and a load generator that is not resource-bound
  by the app under test. Run the heavy soak from a dedicated k6 cloud / runner
  pointed at the deployed URL.
- The SSE gateway (`GET /api/v1/realtime/sse`) holds long-lived connections;
  soak-testing it requires k6's SSE/streaming support or a dedicated SSE client,
  again against a deployed environment.
