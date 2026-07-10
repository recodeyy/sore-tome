# Local vs Render vs AWS Environment Diff — 2026-07-10

| Concern | Local | Render (backend prod) | AWS (website prod) |
|---|---|---|---|
| Backend URL | http://localhost:3001/api/v1 | self | SST Secret SeroBackendUrl → Render |
| NODE_ENV | development | production | production |
| Database | localhost:5544 (DOWN — Docker not running) | managed Postgres (render.yaml fromDatabase; migrations auto) | n/a (BFF only) |
| Redis | localhost:6379 (down, degrades) | dashboard REDIS_URL (Upstash per code comments) — unverified | n/a |
| Firebase | serviceAccountKey.json file | 4 dashboard env vars — verified working | n/a (website doesn't touch Firebase) |
| JWT_SECRET | dev literal | generateValue (managed) | n/a (verifies via backend) |
| Session | n/a | n/a | SST Secret SessionSecret (httpOnly cookies) |
| CORS | localhost origins | was `*` (broken literal) → now CloudFront+localhost | n/a (same-origin BFF) |
| AI keys | plaintext .env.local (rotate if shared) | unverified | SST Secrets, AI_PROXY_MODE=backend |
| Razorpay | Test Mode keys in .env | must exist in dashboard — VERIFY | n/a |
| Mobile API URL | --dart-define override | n/a | n/a (APK defaults to Render URL) |

## Key mismatches found
1. `CORS_ORIGINS` `*` vs literal-match code — fixed in render.yaml.
2. Local DATABASE_URL points at a stopped container — local-only; start Docker or point at a dev Neon branch.
3. Deploy branches: Render deploys `render-live`; GitHub default `master` is stale/unrelated; local master is canonical. Must be reconciled (owner decision) — also gates GitHub Actions keepalive (scheduled workflows run only from the default branch).
