# SERO Admin Web — AWS Deployment Plan

> **STATUS: DEPLOYED & VERIFIED LIVE.** The portal runs on AWS via **SST v3/v4 (ion) + OpenNext**
> (Next.js 14 SSR on Lambda behind CloudFront), built locally — no Git connection.
> Section 0 is the real, executed deployment. Sections 1-7 are the original design notes
> (Amplify was the paper baseline; SST is what actually shipped).

---

## 0. ACTUAL DEPLOYMENT (executed) — SST v3/v4 + OpenNext

**Live URL:** https://d79huy0uhwumb.cloudfront.net  (CloudFront, HTTPS)
**AWS account:** `824604027501`  ·  **Region:** `eu-west-1`  ·  **IAM user:** `fundflow-deployer` (AdministratorAccess)
**Stage:** `production`  ·  **SST app:** `sero-admin-web`  ·  **Resources:** 72 (Pulumi)
**Backend API base wired:** `https://sero-api-live.onrender.com/api/v1` (Render; Neon Postgres + Upstash Redis). GCP Cloud Run is NOT used.

### Verified end-to-end (2026-07-07)
| Check | Result |
|---|---|
| `GET /login` | **200** |
| `POST /api/session/login` (9200000001 / 123456 / admin) | **200** — returns user `sunkist-admin-001` (main_admin, hubtown-sunkist), sets httpOnly cookies `sero_token`, `sero_refresh`, `sero_user` |
| `GET /api/proxy/admin/dashboard/summary` (authed) | **200** — live data (openComplaints 2, maintenanceDue ₹15,930, staffOnDuty 1) |
| `GET /api/session/me` (authed) | **200** |
| `GET /api/proxy/finance/invoices` (no cookie) | **401** (guard works) |

> Note: the Render backend is on the **free plan and cold-starts (~50s)** after idle. The first
> login after a quiet period can return 504/503 for ~1 min while Render wakes up and CloudFront
> edges finish propagating a fresh deploy — then it works. Retry once.

### What was provisioned (all pay-per-use / free-tier eligible — no standing hourly cost)
- **AWS Lambda**: SSR server function (`nodejs`), image optimizer (with `sharp`), revalidation + warmer functions.
- **Amazon CloudFront** distribution (the public HTTPS URL) + CloudFront request Function + cache policies + KeyValueStore.
- **Amazon S3**: static/asset bucket + OpenNext cache bucket.
- **SQS** revalidation queue; **CloudWatch** log groups; small **IAM** roles.
- **SSM Parameter Store**: SST secrets (server-only env). SST state lives in the SST bootstrap S3 bucket (`sst-state-*`) + ECR (`sst-asset`), created once per account/region.
- No RDS, no NAT gateway, no ElastiCache, no App Runner — nothing with a fixed monthly bill.

### ⚠️ Windows build gotchas (documented for reruns — all handled in-repo)
The build must run on **NTFS**, not the repo's `E:\` drive:
1. **`E:\` is exFAT** — no symlinks / no atomic rename, so `bun` (SST's pkg mgr) and OpenNext fail.
   Fix: build/deploy from an NTFS copy at **`C:\sero-deploy`** (recreate with the runbook robocopy).
2. **Node-24 Windows `readlink` EISDIR** during `next build` → `scripts/patch-readlink.cjs` preload shim.
3. **OpenNext image-optimizer bug on Windows**: it derives its temp-install dir name via
   `outputDir.split("/").pop()`, which on a backslash Windows path yields the full path incl. the
   drive colon → `mkdtempSync` throws ENOENT (masked by an OpenNext logger bug). Also, npm walks up
   from the temp dir into `C:\Users\<user>\node_modules` and installs there. Fix: build via
   **`scripts/opennext-build.mjs`**, which (a) forces `os.tmpdir()` to a clean `C:\sst-tmp`
   (only ancestor `C:\` has no node_modules/package.json) and (b) preloads `scripts/patch-mkdtemp.cjs`
   + `scripts/patch-readlink.cjs` into the OpenNext child via `NODE_OPTIONS`. Wired as the SST
   `buildCommand` in `sst.config.ts`. All three shims are **no-ops on Linux/CI**.

### Exact commands run (from `C:\sero-deploy`, an NTFS copy of `sero-admin-web`)
```bash
# 0. Confirm identity (no secrets printed)
aws sts get-caller-identity                      # account 824604027501, eu-west-1

# 1. Deps (SST + OpenNext build wrapper already in the repo)
npm ci

# 2. Server-only secrets -> SSM Parameter Store (values from .env.local; NEVER committed)
npx sst secret set SeroBackendUrl   "https://sero-api-live.onrender.com/api/v1" --stage production
npx sst secret set SessionSecret    "<from .env.local>"                          --stage production
npx sst secret set GroqApiKey       "<from .env.local>"                          --stage production
npx sst secret set GeminiApiKey     "<from .env.local>"                          --stage production
npx sst secret set OpenaiApiKey     "<from .env.local>"                          --stage production
npx sst secret set ElevenLabsApiKey "<from .env.local>"                          --stage production
npx sst secret set ElevenLabsVoiceId "21m00Tcm4TlvDq8ikWAM"                      --stage production

# 3. Deploy. sst.config.ts's buildCommand = `node ./scripts/opennext-build.mjs`, which sets a clean
#    TEMP and preloads the Windows shims for the OpenNext build. (On Linux/CI just `npx sst deploy`.)
mkdir -p /c/sst-tmp
TEMP=C:/sst-tmp TMP=C:/sst-tmp npx sst deploy --stage production
```
To change the backend URL later: re-run the `sst secret set SeroBackendUrl ...` line, then
`TEMP=C:/sst-tmp TMP=C:/sst-tmp npx sst deploy --stage production` (fast — only the Lambda env
updates; CloudFront is untouched).

### Teardown (removes everything this app created; zero residual cost)
```bash
cd /c/sero-deploy
npx sst remove --stage production        # deletes Lambda, CloudFront, S3, SQS, secrets
```
The per-account SST bootstrap (`sst-state-*` bucket + `sst-asset` ECR repo) is shared infra,
left in place; it costs ~$0 (a few KB of state).

### Estimated cost
**~$0/month at this traffic** (internal admin portal, low volume) — everything is pay-per-request
and within the AWS Free Tier envelope:
- Lambda: 1M free req/mo + 400k GB-s. CloudFront: 1 TB + 10M req/mo free (first 12 months).
- S3 (a few MB), SQS, SSM standard params, CloudWatch: negligible.
Realistic worst case if free tier is exhausted: low single-digit USD/month.

---

## 1. Hosting option (recommended)

The app uses SSR + server route handlers (BFF), so a Node-capable host is required.

| Option | Use when | Notes |
|---|---|---|
| **SST v3/v4 + OpenNext** (SHIPPED) | No Git CI/CD; local build | Lambda + CloudFront via CloudFormation-free Pulumi; deployed here |
| **AWS Amplify Hosting** | Managed Next.js SSR w/ Git | Native Next.js 14, CI from Git, per-branch envs — not used (GitHub excluded) |
| **AWS App Runner** (+ Dockerfile) | Prefer containers | `next start` on :3005; autoscale; needs VPC connector to reach backend |
| S3 + CloudFront (static export) | Only if BFF is removed | **Not compatible** with the current httpOnly-cookie BFF |

**Chosen baseline: SST + OpenNext** (builds locally, no Git needed).

## 2. Topology

```
CloudFront (SST) ─> Next.js SSR on AWS Lambda (server function)
                      │  server route handlers (BFF, /app/api/*)
                      └─> SERO backend (Render) ─> Neon Postgres + Upstash Redis
Static assets: S3 (via CloudFront)   ·   Image optimizer: Lambda + sharp
Secrets: SSM Parameter Store (SST secrets)   ·   TLS: CloudFront default cert
Logs: CloudWatch   ·   Revalidation: SQS + Lambda
```

## 3. Build & runtime

- Build: `npm ci` then `npx sst deploy` (OpenNext builds `next build` locally, bundles Lambdas).
- Node: 20+ on AWS Lambda (Windows shims are no-ops on Linux).
- Health: `GET /login` returns 200 (public).

## 4. Secrets (never in the bundle)

Stored as **SST secrets** in **SSM Parameter Store**, injected as Lambda env by `sst.config.ts`:

| Secret (SST name) | Purpose |
|---|---|
| `SeroBackendUrl` | Canonical backend base URL |
| `GroqApiKey` / `GeminiApiKey` / `OpenaiApiKey` | AI (server-only) |
| `ElevenLabsApiKey`, `ElevenLabsVoiceId` | Voice (server-only) |
| `SessionSecret` | Cookie signing |

Never set `NEXT_PUBLIC_*` for any secret.

## 5. Networking / security

- Backend reached over HTTPS (Render). HTTPS-only via CloudFront default cert.
- AWS WAF web ACL + rate-based rule can be attached to the CloudFront distribution later.
- Security headers already emitted by `next.config.mjs` (X-Frame-Options, nosniff, Referrer,
  Permissions-Policy microphone=self).

## 6. Environments

Production is the SST `production` stage. Add a `staging` stage the same way with its own secrets
+ backend URL. See `WEBSITE_ENVIRONMENT_MATRIX.md`.

## 7. Observability & rollback

- CloudWatch log group per Lambda; alarm on SSR 5xx.
- Rollback: `npx sst deploy` from a prior build, or re-set a secret + redeploy. See
  `WEBSITE_DEPLOYMENT_RUNBOOK.md`.
