# DEPLOYMENT_ENV_MATRIX — SERO mobile backend

> Env var × environment. Source of truth for `society-backend`. Keys mirror `society-backend/.env.example` and `render.yaml`.
> Never commit real values. `local` = developer machine (`.env`, gitignored). `render-demo` = free-tier demo. Legend: ✅ required · ⭕ optional · 🔁 auto-wired by platform · 🔐 secret (dashboard/secret-file only).

| Var | Purpose | local (dev) | render-demo | Notes |
|---|---|---|---|---|
| `PORT` | HTTP listen port | `3001` | 🔁 (Render sets `$PORT`) | server.js honours `process.env.PORT` |
| `NODE_ENV` | mode | `development` | `production` | selects knexfile block |
| `ALLOWED_ORIGINS` / `CORS_ORIGINS` | CORS allowlist | `*` | app + website origins (tighten from `*`) | website origin added once AWS domain known |
| `DATABASE_URL` | Postgres DSN | `postgres://sero:sero@localhost:5544/sero_dev` | 🔁 from Neon (paste) / `fromDatabase` | Neon requires `?sslmode=require` |
| `DB_SSL_REJECT_UNAUTHORIZED` | TLS verify toggle | (unset) | `false` | managed PG cert chain not verifiable by Node |
| `DB_POOL_MAX` | pool size | ⭕ `20` | ⭕ `10` (free RAM) | knexfile default 20 |
| `REDIS_URL` | cache/queue | `redis://localhost:6379` | ⭕ `rediss://…` (Upstash) | optional; lazy connect, degrades gracefully |
| `JWT_SECRET` | token signing | dev string | 🔐 `generateValue: true` | rotate → logs everyone out |
| `FIREBASE_PROJECT_ID` | Firebase | `sero-73976` | 🔐 `sync:false` | |
| `FIREBASE_CLIENT_EMAIL` | Firebase admin | ✅ | 🔐 `sync:false` | from service-account JSON |
| `FIREBASE_PRIVATE_KEY` | Firebase admin | ✅ (escaped `\n`) | 🔐 `sync:false` | keep `\n` literal escaping |
| `FIREBASE_STORAGE_BUCKET` | file uploads | `sero-73976.appspot.com` | 🔐 `sync:false` | |
| `PAYMENT_GATEWAY` | gateway select | `razorpay` | `razorpay` | |
| `RAZORPAY_KEY_ID` | checkout | ✅ test `rzp_test_…` | 🔐 test key for demo | **test mode only** |
| `RAZORPAY_KEY_SECRET` | order/verify | 🔐 | 🔐 `sync:false` | never to client |
| `RAZORPAY_WEBHOOK_SECRET` | webhook sig | 🔐 | 🔐 `sync:false` | verifies webhook authenticity |
| `UPI_DEMO_VPA` | demo UPI QR | ⭕ | ⭕ | labelled demo/test only |
| `UPI_DEMO_NAME` | demo payee | ⭕ | ⭕ | |
| `ADMIN_DEMO_MODE` | manual-mark payments | `true` (demo) | `true` (demo) | gates manual UPI marking + audit |
| `SENTRY_DSN` | error monitoring | ⭕ | ⭕ | |
| `LOG_LEVEL` | pino level | ⭕ `debug` | `info` | |

## Flutter build-time defines (`sero`, not backend env)

| Define | Purpose | demo value |
|---|---|---|
| `API_BASE_URL` | backend base | `https://sero-api-prod.onrender.com/api/v1` |
| `FALLBACK_API_URL` | failover base | same as above (or Cloud Run during cutover window) |

Build: `flutter build apk --release --dart-define=API_BASE_URL=https://sero-api-prod.onrender.com/api/v1`

## Secret handling rules

1. `.env`, `serviceAccountKey.json`, `*-adminsdk-*.json` are gitignored — verify with `git check-ignore <file>` before every commit.
2. Render: secrets as `sync: false` env vars or Secret Files; never in `render.yaml`.
3. Razorpay stays in **Test Mode** for all demo environments; real keys never ship in the APK (secret lives server-side; client only gets `RAZORPAY_KEY_ID` at checkout time via an authenticated order response).
