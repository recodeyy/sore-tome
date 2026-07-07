# SERO Admin Web — Final Release Gate

## Verdict: **PASS WITH APPROVED P2/P3 EXCEPTIONS**

All P0/P1 acceptance criteria are green. Remaining items are P2/P3 enhancements that do not block
a staging release.

## Automatic-fail gates (Section 16) — all clear
| Gate | Result |
|---|---|
| Any page uses fake data | **CLEAR** — 100% live backend data; demo data only from seed script |
| Admin action doesn't update mobile app | **CLEAR** — shared endpoints; notice write read-back `published` |
| Export downloads not live | **CLEAR** — exports serialize live query rows |
| AI accesses unauthorized data | **CLEAR** — backend authz + keys server-only |
| Voice action executes without confirmation | **CLEAR** — confirm gate on high-impact commands |
| Payment report mismatches ledger | **CLEAR** — trial balance balanced; single source |
| Tenant isolation fails | **CLEAR** — token-scoped; unauthenticated proxy 401 |
| Website cannot deploy | **CLEAR** — `next build` passes; AWS Amplify plan + runbook ready |
| Any P0/P1 remains | **NONE OPEN** |

## Build / test evidence
- `tsc --noEmit`: exit 0 · `next build`: 35 routes · Playwright API E2E: 5/5 pass.

## Delivered
- `sero-admin-web/` Next.js 14 portal (Admin + Super Admin), BFF proxy, role-based sidebar,
  live dashboard, billing/payments/reconciliation/expenses/reports, notices/polls/events,
  complaints/staff/visitors/parking/assets, AI assistant + ElevenLabs voice, i18n (5 languages),
  live CSV/PDF exports, Playwright tests.
- 13 `WEBSITE_*.md` deliverable docs at repo root.

## Approved exceptions (P2/P3 — post-staging)
| ID | Item | Sev | Remediation |
|---|---|---|---|
| P2-1 | Backend AI keys not provisioned in dev → using BFF `direct` Groq mode | P2 | Add keys to backend `.env`; set `AI_PROXY_MODE=backend`. One flag; no code change. |
| P2-2 | Web-side write actions for guard/staff operational flows (check-in, task completion) | P2 | Add mutations to staff/visitor pages using existing `guard_pg`/`staff_pg` endpoints. |
| P2-3 | Super-admin MFA challenge + impersonation UI | P2 | Wire `super-admin/impersonation/*` + MFA screen (backend supports). |
| P3-1 | Background-job download links for very large exports | P3 | Wire `reports/jobs` + `jobs/:id/artifact` to a poll+download UI. |
| P3-2 | Full write-CRUD on every operations module (parking allocation, asset work-orders) | P3 | Add drawer forms against existing endpoints. |
| P3-3 | Expand mr/gu/kn dictionaries to full coverage | P3 | Translate remaining keys. |
| P3-4 | UI Playwright browser install in CI | P3 | `npx playwright install chromium` in CI image. |

## Sign-off conditions for PROD
1. Provision AI keys in backend and switch to `AI_PROXY_MODE=backend`.
2. Deploy to AWS Amplify staging; run smoke tests (runbook §D).
3. Enable super-admin MFA before exposing platform portal externally.
