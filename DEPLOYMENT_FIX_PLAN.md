# Deployment Fix Plan — 2026-07-10

## P0 — immediate (all addressed)
| ID | Fix | File/Setting | Status | Test |
|---|---|---|---|---|
| P0-1 | Superadmin website login: per-portal demo prefill (was submitting society-admin acct on Super Admin tab → PORTAL_MISMATCH) | sero-admin-web/src/app/login/page.tsx | ✅ code done; deploy via `npm run sst:deploy` | UI: Super Admin tab → sign in → /super-admin/dashboard |
| P0-2 | Resident sections 403/500 (“Something went wrong”): membership self-heal from JWT scope | society-backend/src/services/resident/ResidentService.ts (+resident_pg, parcels_pg, domestic_help_pg) | ✅ code done; deploy via render-live push | `GET /api/v1/resident/family` → 200 with demo resident token |
| P0-3 | Blank screen after idle: 15s client timeout vs 60s cold start | sero/lib/services/api_client.dart (wake+retry) | ✅ code done; **rebuild APK** | fresh APK, idle backend, login succeeds |

## P1 — release blockers
| ID | Fix | Status |
|---|---|---|
| P1-1 | Keep Render instance warm | ✅ .github/workflows/keepalive.yml (activates once pushed to GitHub default branch — note workflows only run from the repo's default branch; master divergence must be resolved for the cron to run) |
| P1-2 | Website login cold-start retry + “waking up” banner | ✅ in login/page.tsx, deploy pending |
| P1-3 | CORS_ORIGINS literal `"*"` never matches | ✅ render.yaml now lists real origins; sync blueprint or set in dashboard |
| P1-4 | Git history divergence (origin/master unrelated & stale; deploys from render-live) | ⏳ OWNER DECISION: force-push master (archive old first) or adopt render-live as canonical deploy branch |

## P2 — polish
- Verify Razorpay keys/REDIS_URL/AI keys present in Render dashboard (masked check).
- Audit second super_admin account `uF8Tyx2aVZqHzIsm8NDM`; disable if unintended.
- Seed staff/guard/treasurer demo accounts + record creds; run role matrix.
- Local dev: document `docker compose up -d` + PG_* vars for localhost:5544.
- `funds/summary` latency (3.8s) — index review.
- Provider-level error/retry UI audit on device (no infinite loaders).

## P3
- Remove demo credentials from public login page + rotate before real production.
- Custom domain + ACM cert for website.
- Rotate AI keys sitting in local `.env.local` if the machine is shared.

## Deploy order
1. Push backend tree to `render-live` (command in RENDER_DEPLOYMENT_REPORT) → Render auto-deploys + runs migrations.
2. Re-run smoke: resident endpoints 200 (esp. /resident/family, /parcels).
3. `cd sero-admin-web && npm run sst:deploy` → verify login page new hints + superadmin flow.
4. `cd sero && flutter build apk --release` → install on device → idle-wake login test.
5. Resolve master divergence (enables keepalive cron on GitHub).
