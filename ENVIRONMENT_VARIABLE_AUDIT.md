# Environment Variable Audit — 2026-07-10

Commit audited: `74361a5` (local master). Values masked per safety rules.

## Backend (society-backend)

| Variable | Local `.env` | Render (blueprint/dashboard) | Consumed by | Failure if missing |
|---|---|---|---|---|
| `NODE_ENV` | `development` | `production` (render.yaml) | server.js CORS dev-bypass, logging | wrong CORS behavior |
| `PORT` | `3001` | Render-injected | server.js | boot failure |
| `DATABASE_URL` | `postgres://sero:****@localhost:5544/sero_dev` (LOCAL ONLY, DB not running) | from managed `sero-postgres` (render.yaml `fromDatabase`); env.dart comments say Neon — verify in dashboard | src/shared/Database.ts | hard crash (`Targeted Failure`) |
| `REDIS_URL` | `redis://localhost:6379` | `sync:false` (dashboard; Upstash per env.dart comment) | lazy ioredis; degrades to no-cache | caching disabled only |
| `JWT_SECRET` | present (dev value) | `generateValue: true` | routes/auth.js | boot/auth failure |
| `CORS_ORIGINS` | localhost:3000,3001 | was `"*"` (BROKEN — literal match) → fixed to CloudFront + localhost | server.js:86 | browser CORS failures |
| `FIREBASE_PROJECT_ID/CLIENT_EMAIL/PRIVATE_KEY/STORAGE_BUCKET` | via `FIREBASE_SERVICE_ACCOUNT_PATH` file | `sync:false` (dashboard) — **verified working**: prod login issues Firebase custom tokens and writes Firestore | config/firebase.js | login 500s, no FCM |
| `RAZORPAY_KEY_ID/KEY_SECRET/WEBHOOK_SECRET` | Test Mode keys present | not in render.yaml — **set in dashboard or payments fail**; UNVERIFIED from here | payments routes | payment creation fails |
| `GEMINI_API_KEY`/`GROQ_API_KEY` | not in backend .env | unknown | AI routes | AI features fail |
| `DB_SSL_REJECT_UNAUTHORIZED` | n/a | `"false"` | knexfile/Database | migration SSL errors |
| `ABUSE_WHITELIST`, `UPI_DEMO_*`, `ADMIN_DEMO_MODE`, `PAYMENT_GATEWAY`, `LOG_LEVEL` | present | partially | misc | demo/test features |

## Website (sero-admin-web)

| Variable | Local `.env.local` | AWS production (SST Secrets → Lambda env) | Notes |
|---|---|---|---|
| `SERO_BACKEND_URL` | `http://localhost:3001/api/v1` | SST Secret `SeroBackendUrl` — **verified live**: CloudFront BFF reaches Render | server-only (BFF), never in browser bundle |
| `SESSION_SECRET` | dev value | SST Secret | httpOnly cookie signing |
| `GROQ/GEMINI/OPENAI/ELEVENLABS_API_KEY` | **real keys in plaintext** (untracked; rotate if machine shared) | SST Secrets (SSM) | `AI_PROXY_MODE=backend` in prod |
| `NEXT_PUBLIC_APP_NAME` | SERO Control | baked at build | public, safe |

## Mobile (sero)

| Item | Value | Status |
|---|---|---|
| `API_BASE_URL` dart-define default | `https://sero-api-live.onrender.com/api/v1` | ✅ correct, HTTPS, no localhost/GCP |
| `FALLBACK_URL` | same | ✅ |
| Firebase Android config | `sero/android/app/google-services.json` (project sero-73976) | present |
| Build flavor | none; default = production | OK for release APK |

## Verdicts

- No secrets in git (only `.env.example` tracked) — PASS.
- Local `.env` DB points at non-running Postgres — local-dev-only issue (P2): run `docker compose up -d` in society-backend (requires Docker Desktop started, and PG_USER/PG_DATABASE/PG_PASSWORD env or compose defaults).
- Items needing a Render-dashboard check (cannot verify from this machine): exact `DATABASE_URL` provider (managed vs Neon), `REDIS_URL`, Razorpay keys presence.
