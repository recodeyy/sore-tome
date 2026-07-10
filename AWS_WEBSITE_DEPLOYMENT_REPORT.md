# AWS Website Deployment Report — 2026-07-10

- Stack: SST v3 (ion) + OpenNext → Lambda (SSR + route handlers) + CloudFront + S3, AWS account `824604027501`, region `eu-west-1`, stage `production`.
- Live URL: `https://d79huy0uhwumb.cloudfront.net` — 200, HTTPS, valid cert.
- Build: local (`node ./scripts/opennext-build.mjs`, Windows tmpdir + readlink shims documented in sst.config.ts).
- Secrets: SSM via `sst secret` (SeroBackendUrl, SessionSecret, AI keys) — injected as Lambda env, never in bundle or git. Verified: BFF reaches Render backend.
- SPA/SSR routing: Next.js on Lambda; `/login`, `/dashboard`, `/super-admin/dashboard` all render (200). No SPA-fallback issue.
- CloudFront caching: API/session routes uncached (no-store observed via fresh backend errors round-tripping); acceptable.
- Bundle checks: no localhost/GCP URL in client bundle (base URL is server-only); no secrets exposed (`NEXT_PUBLIC_*` only app name).

## Pending deploy
Login-page fix (superadmin prefill + wake-retry) is committed locally but NOT yet deployed. Deploy with:
```
cd sero-admin-web && npm run sst:deploy
```
(requires the AWS credentials/profile used for previous deploys on this machine).

## Notes
- Known cold-start interaction: after backend idle, first login could 504 — mitigated by the new retry + keepalive.
- Custom domain/ACM: not configured; CloudFront default domain in use (P3 polish).
