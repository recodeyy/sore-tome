# MOBILE_REVAMP_DEPLOYMENT_PLAN

> 2026-07-07. Resolves §15 (§18 deliverable #6). This is the summary/index; full detail in the three deployment docs.

## Docs

| Doc | Content |
|---|---|
| `DEPLOYMENT_FREE_LOW_COST_PLAN.md` | Target stack, free-tier limits, costs, why-this-split |
| `DEPLOYMENT_ENV_MATRIX.md` | Every env var × environment (local / render-demo) + Flutter defines + secret rules |
| `DEPLOYMENT_RUNBOOK.md` | Step-by-step provision → deploy → seed → build APK → two-device smoke → cutover/rollback |
| `MOBILE_REVAMP_DEPLOYMENT_MIGRATION_PLAN.md` | Original GCP-exit migration plan (audit) |

## Chosen stack (demo, ~$0)

- **API:** Render web service (docker, `render.yaml` blueprint, `/health`, `preDeployCommand: knex migrate:latest`). New name `sero-api-prod` — never reuse the third-party-reclaimed `sero-api.onrender.com`.
- **Postgres:** Neon free (no 90-day cliff; pgvector).
- **Redis:** Upstash free (optional — app boots without it).
- **Files / Auth / FCM / Firestore:** keep Firebase (`sero-73976`) — independent of expiring GCP compute.
- **APK distribution:** GitHub Releases.
- **Admin website:** separate AWS plan (`WEBSITE_AWS_DEPLOYMENT_PLAN.md`).

## App configurability

`sero/lib/config/env.dart` reads `API_BASE_URL` from `--dart-define`; default currently the GCP URL. Cutover = change default (or pass define) + rebuild + redistribute APK before GCP lapses.

## Status

- 🟡 **MR-002 open until executed.** Docs + blueprint are complete and deploy-ready. **Provisioning requires the user's Render + Neon + Upstash accounts** — not performed here (no credentials, and it provisions live cloud resources / cost). Zero-blocker once accounts exist; the runbook is a ~45-min checklist.
- ⚠️ **MR-003:** stray `sero-73976-firebase-adminsdk-*.json` in the working dir is **git-ignored/untracked** (verified) but should be deleted from disk and the key rotated in Firebase console.
