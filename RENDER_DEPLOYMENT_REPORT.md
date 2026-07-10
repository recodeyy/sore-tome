# Render Deployment Report — 2026-07-10

## Service
- Live URL: `https://sero-api-live.onrender.com` (service name likely `sero-api-live`; render.yaml blueprint names `sero-api` — reconcile in dashboard).
- Runtime: Docker (`society-backend/Dockerfile`), rootDir `society-backend`, health check `/health`, `preDeployCommand: npx knex migrate:latest`.
- Plan: **free** — instance sleeps after ~15 min idle; measured cold start >60s. This was the top production pain (see BLANK_SCREEN report). Mitigations: keepalive workflow + client wake-retry. Real fix: paid plan.
- **Deploy branch: `render-live`** (GitHub `recodeyy/sore-tome`), NOT `master`. Live behavior matches render-live snapshot f6bbd31 (2026-07-09). GitHub `master` is a stale unrelated history from 2026-06-21 — see git-hygiene note below.

## Verified from outside
- Health 200; migrations current (API surface complete through parcels/domestic-help tables).
- Env vars: JWT, Firebase (4 vars), DATABASE_URL working by behavior. Unverified from here: REDIS_URL, Razorpay keys, AI keys — check dashboard.
- No crash-looping observed (consistent sub-second warm responses across many calls).

## Dashboard checks still recommended (need dashboard access)
- Latest deploy status/commit SHA vs render-live f6bbd31.
- Runtime logs for the `logger.warn` "Firebase custom token generation failed" (should be absent), restart count, memory.

## Pending deploy (approved command needed)
Backend fixes (74361a5: membership self-heal + CORS origins) must reach the `render-live` branch:
```
git push origin $(git commit-tree "HEAD^{tree}" -p origin/render-live -m "Deploy: membership self-heal + cold-start + CORS fixes"):refs/heads/render-live
```
(creates a fast-forward commit on render-live carrying the exact local tree — no history rewrite).

## Git hygiene (P2)
`origin/master` (bd5d305, 2026-06-21) shares no ancestor with local master (74361a5, re-initialized during production recovery). Options: (a) force-push local master after archiving old master to a branch, or (b) keep using render-live as the deploy branch and treat master as archive. Requires owner decision — force-push was intentionally not performed.
