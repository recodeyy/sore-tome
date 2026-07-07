# RECOVERY — Deployment Audit (Render + GCP), verified live

> Date: 2026-06-25 · Probed live with `curl` + `gcloud`. **Contains a P0 finding.**

## TL;DR — the SERO backend is NOT deployed at any reachable production URL.

| Target | Documented as | Live reality | Verdict |
|---|---|---|---|
| `https://sero-api.onrender.com` | Production API (`DEPLOY.md`, `BUILD_APK.md`) | **Serving a DIFFERENT app** (Korean, `{success,message}` envelope) | 🔴 **P0 — wrong/hijacked** |
| GCP `sero-73976` ("Sero") | (prompt assumes GCP prod) | Cloud Run / Compute / App Engine **never enabled**. Firebase-only project. | 🔴 Never deployed |
| GCP `sero-loadtest-2026` | Load-test infra | Cloud Run disabled; only used for load-test VMs | n/a |
| `localhost:3001` | Local dev | ✅ Healthy, current code | ✅ Only working SERO backend |

## P0 finding — DEPLOY-001: production URL serves a foreign application

`sero-api.onrender.com` is a live Render service, but **not SERO**:

| Probe | LOCAL SERO (real) | PROD `sero-api.onrender.com` |
|---|---|---|
| `GET /health` | `{"status":"ok","app":"Society Backend",...}` | `{"status":"ok",...}` — **no `app` field** |
| `GET /` | `{"error":"Route GET / not found"}` | `{"success":false,"message":"Route GET / not found"}` |
| `POST /api/v1/auth/login {}` | `{"error":"Validation failed","details":[…]}` | `{"success":false,"message":"이메일과 비밀번호를 입력해주세요"}` (**Korean**) |
| `GET /api/v1/notices-v2` | 200 (scoped) / 409 | **404** |

- The SERO codebase contains **zero Korean strings** (`grep` → none) and uses an `{"error":…}` envelope, never `{"success":false,"message":…}`.
- **Root cause:** Render **free-tier** services are suspended after inactivity and their subdomains can be **reclaimed by other users**. The original `sero-api` SERO deployment is gone; the subdomain now points at an unrelated app.
- **Impact:** Any APK built with `API_BASE_URL=https://sero-api.onrender.com/api/v1` **cannot work** — it talks to a stranger's backend. This is exactly the prompt §21 failure "GCP/prod config differs silently from tested environment."

## GCP topology (actual)
- `sero-73976` = **Firebase project only** (Auth + Firestore for login/users, FCM). Cloud Run, Compute Engine, App Engine APIs are all **disabled / never used** → backend was never hosted on GCP.
- `deploy/gcp/` in the repo = **load-test VM scripts only** (nginx + k6-style), not the API host.
- Active gcloud account: `avinashgehi3@gmail.com`; default project was `mediflow-nexus-2026` (an unrelated project).

## Deployment access available on this machine
- **Render:** no CLI installed, no `~/.render` auth → **cannot redeploy programmatically** (needs the owner's Render dashboard; `render.yaml` blueprint is ready).
- **GCP `sero-73976`:** gcloud authenticated; APIs disabled but enable-able **if billing is active**. Cloud Run deploy is feasible but needs Cloud SQL (Postgres) + Memorystore/Redis + Secret Manager + env wiring (billable, multi-step).
- **cloudflared** is installed (in PATH) → a **temporary public tunnel** to `localhost:3001` is possible for demo/teammate testing.

## Recommended production paths (pick one — see decision)
1. **Cloud Run on `sero-73976`** (matches prompt's GCP intent; stable URL; needs Cloud SQL+Redis+secrets; billable). Most "correct," most setup.
2. **Re-deploy to Render** via the existing `render.yaml` blueprint (owner does it in dashboard; paid tier to avoid subdomain reclaim). Least code change.
3. **cloudflared tunnel** to local backend (instant, free, temporary) — good for the demo/teammate test now; not a permanent prod.
4. **LAN/localhost APK** — emulator (`10.0.2.2`) or same-WiFi LAN IP; dev/demo only.

## Env diff (local vs intended prod)
- Local `.env`: `NODE_ENV=development`, `DATABASE_URL=postgres://sero:***@localhost:5544/sero_dev`, `FIREBASE_PROJECT_ID=sero-73976`, Redis local. Razorpay keys **absent** (feature-gated off).
- Prod needs: managed Postgres URL, managed Redis, `NODE_ENV=production`, `CORS_ORIGINS`, Firebase SA (same `sero-73976`), and Razorpay **test** keys in Secret Manager — none committed.
