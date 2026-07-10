# SERO Admin Web — Deployment Runbook

> **Live:** https://d79huy0uhwumb.cloudfront.net · AWS `824604027501` · `eu-west-1` · stage `production`
> Deployed with **SST v3/v4 + OpenNext** (local build, no Git). Backend: `https://sero-api-live.onrender.com/api/v1`.

## A. Local development

```bash
cd sero-admin-web
cp .env.example .env.local                # fill keys (dev keys already present locally)
npm install
npm run dev                               # http://localhost:3005
```
Demo logins (password `123456`): admin `9200000001` (portal Admin) · super admin via seeded login.

## B. Build & verify (CI gate)

```bash
cd sero-admin-web
npm run typecheck        # tsc --noEmit  -> exit 0
npm run build            # next build (35 routes)  -> success
npm run test:e2e         # Playwright (needs web :3005 + backend :3001 up)
```

## C. Deploy to AWS — SST v3/v4 + OpenNext (EXECUTED path, no Git needed)

> Builds the Next.js app **locally** and deploys SSR to **Lambda + CloudFront** via SST.

### C.0 — One-time: use an NTFS build workspace (the repo drive `E:\` is exFAT)
exFAT can't do symlinks or bun's atomic lockfile rename, so `bun`/OpenNext fail on `E:\`.
Build+deploy from an NTFS copy (`C:\sero-deploy`). Recreate it any time with:
```powershell
robocopy "E:\All projects\Society management\sore-tome\sero-admin-web" "C:\sero-deploy" `
  /E /XD node_modules .next .sst test-results .git /XF tsconfig.tsbuildinfo
```
Then `cd C:\sero-deploy`. The three Windows build shims (`scripts/patch-readlink.cjs`,
`scripts/patch-mkdtemp.cjs`, `scripts/opennext-build.mjs`) travel with the repo and are no-ops on Linux.

### C.1 — Deploy
```bash
cd /c/sero-deploy
aws sts get-caller-identity                 # sanity: account 824604027501, eu-west-1
npm ci                                       # sst + build wrapper are in the repo

# secrets -> SSM (values come from .env.local; NEVER commit them). One-time / on change:
npx sst secret set SeroBackendUrl   "https://sero-api-live.onrender.com/api/v1" --stage production
npx sst secret set SessionSecret    "<from .env.local>"  --stage production
npx sst secret set GroqApiKey       "<from .env.local>"  --stage production
npx sst secret set GeminiApiKey     "<from .env.local>"  --stage production
npx sst secret set OpenaiApiKey     "<from .env.local>"  --stage production
npx sst secret set ElevenLabsApiKey "<from .env.local>"  --stage production
npx sst secret set ElevenLabsVoiceId "21m00Tcm4TlvDq8ikWAM" --stage production

# deploy — sst.config.ts buildCommand runs scripts/opennext-build.mjs, which forces a clean
# TEMP (C:\sst-tmp) and preloads the readlink + mkdtemp shims into the OpenNext build.
mkdir -p /c/sst-tmp
TEMP=C:/sst-tmp TMP=C:/sst-tmp npx sst deploy --stage production
```
SST prints the CloudFront `url` on completion. (A clean Linux/WSL/CI build needs no TEMP/shims.)

If a prior run aborted and left a lock: `npx sst unlock --stage production`, then redeploy.

### C.2 — Change the backend URL (e.g. new API host)
```bash
npx sst secret set SeroBackendUrl "https://<new-api>/api/v1" --stage production
TEMP=C:/sst-tmp TMP=C:/sst-tmp npx sst deploy --stage production
```
Only the Lambda env changes; CloudFront is untouched (fast redeploy).

### C.3 — Teardown
```bash
cd /c/sero-deploy && npx sst remove --stage production
```

## D. Smoke test after deploy

```bash
BASE=https://d79huy0uhwumb.cloudfront.net
curl -s $BASE/login -o /dev/null -w "login-page %{http_code}\n"             # expect 200
# BFF login -> backend /auth/login, sets httpOnly cookies (portal=admin):
curl -s -c cj -X POST $BASE/api/session/login -H 'Content-Type: application/json' \
  -d '{"phone":"9200000001","password":"123456","portal":"admin"}' -w "\nsession-login %{http_code}\n"
curl -s -b cj $BASE/api/proxy/admin/dashboard/summary                       # expect live JSON
curl -s $BASE/api/proxy/finance/invoices -o /dev/null -w "guard %{http_code}\n"  # expect 401
```
> The Render backend is on the free plan and **cold-starts (~50s)** after idle — the first
> `session-login` after a quiet period (or right after a fresh deploy) may return 504/503 for
> up to a minute before it warms up. Retry once.

## E. Rollback

- Redeploy a previous build with `npx sst deploy`, or re-set a secret and redeploy.
- SST keeps Pulumi state; `sst.config.ts` sets `removal: retain` on production.
- Cookies/secrets are backward compatible across builds; the web app owns no DB migration.

## F. Health & monitoring

- Health path: `GET /login` (200, public).
- CloudWatch log group per Lambda; alarm on SSR 5xx.
- Backend outages surface in-app as error states with Retry (no crash, no raw JSON).
