# APP_ONLY_DEPLOYMENT_SECRETS_CHECKLIST

> 2026-07-07. What must never be committed, where each secret lives, and its current state.

## Never commit (verified)

| Secret | Where it lives | Committed? |
|---|---|---|
| Android keystore / password | `**/key.properties`, `**/*.keystore`, `**/*.jks` | ✅ gitignored |
| Firebase private key / admin JSON | `**/*firebase-adminsdk*.json` (gitignored); backend `.env` | ✅ not tracked (verified `git check-ignore`) |
| Razorpay secret / webhook secret | backend `.env` | ✅ `**/.env` gitignored |
| AI keys (Gemini/Groq/OpenAI/ElevenLabs) | backend `.env` / website `.env.local` | ✅ gitignored; `.env.example` placeholders only |
| `DATABASE_URL` (Neon) | env var / Render dashboard `sync:false` | ✅ not in repo |
| `REDIS_URL` (Upstash) | env var / Render dashboard | ✅ not in repo |
| Production `JWT_SECRET` | Render `generateValue:true` | ✅ not in repo |
| `google-services.json` | in APK, gitignored in source | ✅ `**/google-services*.json` gitignored |

## `.gitignore` coverage (confirmed)

`**/.env`, `**/*firebase-adminsdk*.json`, `**/serviceAccountKey.json`, `**/google-services*.json`, `**/key.properties`, `**/*.keystore`, `**/*.jks`, `*.zip`, `*.exe`.

## Action items

1. ⚠️ **Delete on-disk** `sero-73976-firebase-adminsdk-*.json` (untracked but present) and **rotate** the key in Firebase console — it was shared around during setup.
2. When creating the Render service, set all `sync:false` secrets in the dashboard (never in `render.yaml`).
3. Keep Razorpay in **Test Mode** for all demo environments; the secret never ships in the APK (client only receives `RAZORPAY_KEY_ID` in an authenticated order response).
4. `.env.example` (committed) lists every var name with placeholder values — no real secrets.

## Provided-but-restricted

- A GitHub token was supplied but the user instructed to **ignore** it; it is not used for any app credential and must not be committed.
