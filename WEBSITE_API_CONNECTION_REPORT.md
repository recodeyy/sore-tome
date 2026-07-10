# Website API Connection Report — 2026-07-10 (live production)

Website: `https://d79huy0uhwumb.cloudfront.net` (SST → Lambda + CloudFront, eu-west-1, stage `production`)

## Architecture
Browser → CloudFront → Next.js SSR/route handlers (Lambda) → **server-side BFF** (`src/lib/backend.ts`) → Render backend.
The backend URL is the SST Secret `SeroBackendUrl` injected as Lambda env `SERO_BACKEND_URL`. It is **never in the browser bundle**; the browser only calls same-origin `/api/session/*` and page routes → no browser↔Render CORS in play, no secret exposure.

## Live tests
| Test | Result |
|---|---|
| `GET /` | 200 (3.4s first hit) |
| `GET /login` | 200 |
| `POST /api/session/login` bad creds | 401 with backend's error surfaced (`Invalid phone number or password`) in ~2s ⇒ BFF → Render link healthy and pointing at the right backend |
| `POST /api/session/login` admin/123456/admin | 200, sets `sero_token`, `sero_refresh`, `sero_user` httpOnly cookies |
| superadmin/123456/super-admin | 200, role `super_admin` |
| `GET /super-admin/dashboard` with cookies | 200 |
| `GET /dashboard` with cookies | 200 |

## Base URL verification
- Does not point at localhost (verified behaviorally: CloudFront BFF returns live Render responses).
- No expired GCP URL anywhere in web src (grep clean).
- HTTPS end-to-end.

## Defect found & fixed (superadmin "login not working")
The login page pre-filled `9200000001` (a society-admin). Choosing the **Super Admin** tab and submitting returned PORTAL_MISMATCH ("This account does not have access to the selected portal") — correct backend behavior, wrong prefill. Fixed in `src/app/login/page.tsx`:
- per-portal demo prefill/hint (Super Admin tab → `superadmin` / `123456`),
- wake-and-retry on 502/503/504 with "Server is waking up, retrying…" notice (Render cold start).
Deploy via `npm run sst:deploy` in sero-admin-web.

Note (P3): demo credentials shown on the public login page are fine for demo mode but must be removed (and passwords rotated) before real-customer production.
