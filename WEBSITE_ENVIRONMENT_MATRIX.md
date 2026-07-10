# SERO Admin Web — Environment Matrix

> **Production (AWS) is live** at https://d79huy0uhwumb.cloudfront.net (SST, stage `production`).
> Server-only vars are **SST secrets** in **SSM Parameter Store** (set with
> `npx sst secret set <Name> <value> --stage production`) and injected into the Lambda runtime by
> `sst.config.ts` (`environment: {...}`). They are never in the bundle and never committed.

| Variable | Local (`.env.local`) | Production (AWS, SST) | SST secret name | Exposure |
|---|---|---|---|---|
| `SERO_BACKEND_URL` | `http://localhost:3001/api/v1` | `https://sero-api-live.onrender.com/api/v1` | `SeroBackendUrl` | server-only |
| `NEXT_PUBLIC_APP_NAME` | `SERO Control` | `SERO Control` (in `sst.config.ts`) | — (plain env) | public (safe) |
| `AI_PROXY_MODE` | `direct` (backend unkeyed locally) | `backend` (plain env) | — | server-only |
| `GROQ_API_KEY` | dev key | SSM (SST secret) | `GroqApiKey` | **server-only** |
| `GEMINI_API_KEY` | dev key | SSM (SST secret) | `GeminiApiKey` | **server-only** |
| `OPENAI_API_KEY` | dev key | SSM (SST secret) | `OpenaiApiKey` | **server-only** |
| `ELEVENLABS_API_KEY` | dev key | SSM (SST secret) | `ElevenLabsApiKey` | **server-only** |
| `ELEVENLABS_VOICE_ID` | `21m00Tcm4TlvDq8ikWAM` | SSM (SST secret) | `ElevenLabsVoiceId` | server-only |
| `SESSION_SECRET` | dev string | SSM (SST secret) | `SessionSecret` | **server-only** |
| `NODE_ENV` | `development` | `production` (plain env) | — | — |

## Rules

- **Only** `NEXT_PUBLIC_*` variables reach the browser bundle. No secret is ever `NEXT_PUBLIC_*`.
- `.env.local` is git-ignored; only `.env.example` (placeholders) is committed.
- Cookies are `Secure` automatically when `NODE_ENV=production` (see `lib/session.ts`).
- `AI_PROXY_MODE`: `backend` forwards to the canonical backend `/ai/chat` (preferred); `direct`
  makes the BFF call Groq with a server-side key (local fallback). Keys never reach the browser.
- Data plane behind the backend: **Neon Postgres** + **Upstash Redis**, seeded with society
  `hubtown-sunkist`, flat `A-1402`; demo logins phone `9200000001/2/3`, password `123456`.

## Ports (local dev)

| Service | Port |
|---|---|
| Web (Next.js) | 3005 |
| Backend (shared, do not co-opt) | 3001 |
| Postgres (dev) | 5544 |
| Redis (dev) | 6379 |
