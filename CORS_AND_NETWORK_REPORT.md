# CORS and Network Report — 2026-07-10

## CORS implementation (server.js:85-100)
- Literal string match of `Origin` against `CORS_ORIGINS` (comma list); origin-less requests (mobile, curl, server-to-server) always allowed; `NODE_ENV=development` bypasses.
- `credentials: true`; methods GET/POST/PUT/PATCH/DELETE/OPTIONS; headers Content-Type, Authorization, X-Requested-With, x-health-check-secret.

## Defect (P3, fixed): `CORS_ORIGINS="*"` on Render
`"*"` is compared literally and matches no real origin ⇒ any direct browser call to the API would fail preflight. Currently latent (website uses a server-side BFF, mobile has no Origin). Fixed in render.yaml → `https://d79huy0uhwumb.cloudfront.net,http://localhost:3000,http://localhost:3001`. Also removes the `*`+credentials smell.

## Path matrix
| Path | Status |
|---|---|
| Website origin → backend | N/A by design (BFF server-side); verified Lambda→Render works (2s round trip) |
| Local dev website → backend | allowed via localhost origins in CORS_ORIGINS |
| Mobile → backend | ✅ no Origin header, always allowed, HTTPS |
| Razorpay webhook → backend | server-to-server, no CORS; needs `RAZORPAY_WEBHOOK_SECRET` on Render (verify in dashboard) |
| Backend → Firestore/FCM | ✅ verified (custom tokens issued, Firestore writes on login) |
| Backend → Postgres | ✅ verified via data endpoints; SSL `rejectUnauthorized:false` |
| Backend → Redis | lazy/degrading; unverified from here (dashboard REDIS_URL) |
| Backend → AI providers | unverified from here |

## TLS
- CloudFront and onrender.com certs valid (HTTPS 200s). No mixed content: website only calls same-origin + HTTPS.

## Timeouts
- Mobile: was a flat 15s (fatal with cold starts) — fixed with wake-retry.
- Website BFF fetch: Lambda default timeout applies; login route now retries 502/503/504.
- Backend must be kept warm (keepalive workflow) to keep p95 sane on the free plan.
