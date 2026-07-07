# SERO Admin Web — AWS Deployment Plan

> No AWS resources were provisioned (zero cost). This is the deploy-ready plan.

## 1. Hosting option (recommended)

The app uses SSR + server route handlers (BFF), so a Node-capable host is required.

| Option | Use when | Notes |
|---|---|---|
| **AWS Amplify Hosting** (recommended) | Managed Next.js SSR | Native Next.js 14 support, CI from Git, per-branch envs, ACM+CDN built in |
| **AWS App Runner** (+ Dockerfile) | Prefer containers | `next start` on :3005; autoscale; needs VPC connector to reach backend |
| **SST / OpenNext on AWS** | Team comfortable with IaC | Lambda + CloudFront, fine-grained |
| S3 + CloudFront (static export) | Only if BFF is removed | **Not compatible** with the current httpOnly-cookie BFF; would require moving proxy to API Gateway + Lambda |

**Chosen baseline: AWS Amplify Hosting** for staging and production.

## 2. Topology

```
Route 53 (optional) ─> CloudFront (Amplify) ─> Next.js SSR (Amplify compute)
                                                   │  server route handlers (BFF)
                                                   └─> SERO backend (App Runner / EC2 / ECS) ─> RDS Postgres + ElastiCache Redis
Secrets: AWS Secrets Manager / SSM Parameter Store
TLS: AWS Certificate Manager (ACM)
Logs/metrics: CloudWatch
Edge protection: AWS WAF (rate limits, IP rules) on CloudFront
```

## 3. Build & runtime

- Build command: `npm ci && npm run build`
- Start command (App Runner/container): `npm start` (`next start -p 3005`)
- Node: 20 LTS on AWS (the Windows `readlink` shim is a no-op on Linux; harmless to keep).
- Health: `GET /login` returns 200 (public) — use as the platform health check path.

## 4. Secrets (never in the bundle)

Store in **Secrets Manager** (or SSM SecureString) and inject as env at deploy time:

| Secret | Purpose |
|---|---|
| `SERO_BACKEND_URL` | Canonical backend base URL |
| `GROQ_API_KEY` / `GEMINI_API_KEY` / `OPENAI_API_KEY` | AI (server-only) |
| `ELEVENLABS_API_KEY`, `ELEVENLABS_VOICE_ID` | Voice (server-only) |
| `SESSION_SECRET` | Cookie signing |

Never set `NEXT_PUBLIC_*` for any secret. Rotate keys via Secrets Manager rotation.

## 5. Networking / security

- Put the backend behind a private endpoint; allow the Amplify/App Runner compute egress to it.
- Enforce HTTPS-only (ACM cert on the custom domain via Route 53 if the domain is available).
- WAF managed rules + a rate-based rule (mirrors backend `express-rate-limit`).
- Security headers already emitted by `next.config.mjs` (X-Frame-Options, nosniff, Referrer,
  Permissions-Policy microphone=self).

## 6. Environments

Staging and production are separate Amplify branches/apps with separate secrets and backend
URLs. See `WEBSITE_ENVIRONMENT_MATRIX.md`.

## 7. Observability & rollback

- CloudWatch log group per environment; alarm on 5xx rate and SSR errors.
- Optional Sentry (frontend) — add `@sentry/nextjs` and a server DSN secret.
- Rollback: Amplify keeps prior builds — redeploy the last green build (one click / CLI). For
  App Runner, pin to the previous image tag. See `WEBSITE_DEPLOYMENT_RUNBOOK.md`.
