# SERO Admin Web — Environment Matrix

| Variable | Local (`.env.local`) | Staging (AWS) | Production (AWS) | Exposure |
|---|---|---|---|---|
| `SERO_BACKEND_URL` | `http://localhost:3001/api/v1` | staging backend URL | prod backend URL | server-only |
| `NEXT_PUBLIC_APP_NAME` | `SERO Control` | `SERO Control (Staging)` | `SERO Control` | public (safe) |
| `AI_PROXY_MODE` | `direct` (backend unkeyed locally) | `backend` (once keyed) | `backend` | server-only |
| `GROQ_API_KEY` | dev key | Secrets Manager | Secrets Manager | **server-only** |
| `GEMINI_API_KEY` | dev key | Secrets Manager | Secrets Manager | **server-only** |
| `OPENAI_API_KEY` | dev key | Secrets Manager | Secrets Manager | **server-only** |
| `ELEVENLABS_API_KEY` | dev key | Secrets Manager | Secrets Manager | **server-only** |
| `ELEVENLABS_VOICE_ID` | `21m00Tcm4TlvDq8ikWAM` | configurable | configurable | server-only |
| `SESSION_SECRET` | dev string | Secrets Manager | Secrets Manager | **server-only** |
| `NODE_ENV` | `development` | `production` | `production` | — |

## Rules

- **Only** `NEXT_PUBLIC_*` variables reach the browser bundle. No secret is ever `NEXT_PUBLIC_*`.
- `.env.local` is git-ignored; only `.env.example` (placeholders) is committed.
- Cookies are `Secure` automatically when `NODE_ENV=production` (see `lib/session.ts`).
- `AI_PROXY_MODE`:
  - `backend` — forward to the canonical backend `/ai/chat` (preferred; backend holds keys).
  - `direct` — BFF calls Groq directly with a server-side key (used locally because the dev
    backend has no AI keys). Keys still never reach the browser.

## Ports

| Service | Port |
|---|---|
| Web (Next.js) | 3005 |
| Backend (shared, do not co-opt) | 3001 |
| Postgres (dev) | 5544 |
| Redis (dev) | 6379 |
