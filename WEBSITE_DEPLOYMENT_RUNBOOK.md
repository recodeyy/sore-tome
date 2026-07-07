# SERO Admin Web — Deployment Runbook

## A. Local development

```bash
# 1. Backend (shared) must be running on :3001 with the Hubtown Sunkist seed applied
#    (Postgres :5544, Redis :6379 already up in this environment).
cd society-backend && npm start           # if not already running

# 2. Web portal
cd sero-admin-web
cp .env.example .env.local                # fill keys (dev keys already present locally)
npm install
npm run dev                               # http://localhost:3005
```

Demo logins (password `123456`): admin `9200000001` (portal Admin) ·
super admin `superadmin` (portal Super Admin). Seed super-admin login once if missing:
`node society-backend/scripts/seed_test_logins.js`.

## B. Build & verify (CI gate)

```bash
cd sero-admin-web
npm run typecheck        # tsc --noEmit  -> exit 0
npm run build            # next build (35 routes)  -> success
npm run test:e2e         # Playwright (needs web :3005 + backend :3001 up)
```

E2E notes:
- API cross-role specs need no browser and pass in ~2s.
- The UI spec needs `npx playwright install chromium` (one-time browser download).
- The backend auth limiter is **5 logins / 15 min / IP**. If re-running rapidly trips it,
  clear dev keys: from `society-backend`, `node -e "const R=require('ioredis');const r=new R('redis://localhost:6379');r.keys('*rl*').then(k=>k.length&&r.del(...k)).then(()=>r.disconnect())"`.

## C. Deploy to AWS Amplify (staging)

1. Push `sero-admin-web/` to the Git repo connected to Amplify.
2. In Amplify: create app → connect branch `staging` → framework auto-detected (Next.js SSR).
3. Build settings: `npm ci && npm run build`; output handled by Amplify Next.js runtime.
4. Environment variables: add all from `WEBSITE_ENVIRONMENT_MATRIX.md`; back secrets with
   Secrets Manager references. Set `AI_PROXY_MODE=backend` once the backend is keyed.
5. Attach domain (Route 53 + ACM) if available; else use the Amplify default HTTPS URL.
6. Attach WAF web ACL to the CloudFront distribution.

Production is the same on a `production` branch with production secrets + backend URL.

## D. Smoke test after deploy

```bash
BASE=https://<amplify-url>
curl -s $BASE/login -o /dev/null -w "login %{http_code}\n"                 # expect 200
# authenticated smoke (replace creds):
curl -s -c cj -X POST $BASE/api/session/login -H 'Content-Type: application/json' \
  -d '{"phone":"9200000001","password":"...","portal":"admin"}' -o /dev/null -w "login %{http_code}\n"
curl -s -b cj $BASE/api/proxy/admin/dashboard/summary                       # expect live JSON
curl -s $BASE/api/proxy/finance/invoices -o /dev/null -w "guard %{http_code}\n"  # expect 401
```

## E. Rollback

- **Amplify:** open the app → Deployments → select last green build → **Redeploy this version**.
- **App Runner/container:** update the service to the previous image tag; wait for health check.
- Cookies/secrets are backward compatible across builds; no DB migration is owned by the web app.

## F. Health & monitoring

- Health path: `GET /login` (200, public).
- CloudWatch: alarm on SSR 5xx and elevated error rate.
- Backend outages surface in-app as error states with Retry (no crash, no raw JSON).
