# SERO Admin Web — E2E / Test Report

## Tooling
- **Typecheck**: `tsc --noEmit`
- **Build**: `next build`
- **E2E**: Playwright (`tests-e2e/`) — API-level (request context, no browser) + UI smoke.

## Results (this session)

| Suite | Command | Result |
|---|---|---|
| Typecheck | `npm run typecheck` | **PASS** (exit 0) |
| Production build | `npm run build` | **PASS** — 35 routes compiled |
| API cross-role E2E | `npx playwright test tests-e2e/api-crossrole.spec.ts` | **5/5 PASS (2.0s)** |
| UI login smoke | `tests-e2e/ui-login.spec.ts` | Ready — needs `npx playwright install chromium` |

### API cross-role specs (all passing)
1. `admin sees live invoices (no mock)` — invoices array non-empty from live backend.
2. `unauthenticated proxy is rejected` — 401 without a session.
3. `admin notice write persists to shared backend` — create → publish → read-back `published`.
4. `super-admin dashboard returns live metrics` — `active_users` metric present.
5. `AI proxy responds without exposing keys` — non-empty `reply`, key server-side only.

## Manual curl E2E (evidence)
```
login (BFF)                → 200, sets httpOnly sero_token
GET  finance/invoices      → live INV-SK-001.. rows
GET  admin/dashboard/summary → {openComplaints:2, maintenanceDueMinor:1593000, ...}
POST notices-v2 + publish  → 200; read-back status=published
POST /api/ai/chat          → {"reply":"...","provider":"groq"}
POST /api/voice/tts        → 200, 20 KB valid MP3 (ElevenLabs)
proxy w/o cookie           → 401
super-admin/dashboard      → metrics (active_users=14, health=operational)
```

## Mapping to Section 15 "Required E2E"
| # | Required flow | Coverage |
|---|---|---|
| 1 | Super Admin approves society | `applications/:id/review` wired + UI (`/super-admin/applications`) |
| 2 | Admin creates society structure | `structure_pg` endpoints available; members/units live |
| 3–4 | Resident requests A-1402 → admin approves | `members-v2/join-requests/*` (cross-role report) |
| 5 | Admin generates bill | **covered** — billing create/publish live |
| 6–7 | Resident pays → web collection updates | Razorpay webhook + `finance/reports/summary` (live) |
| 8–9 | Admin publishes notice → resident notified | **covered & verified** (spec #3) |
| 10–12 | Guard delivery approval → live entry | `guard/visitors` live read verified |
| 13–14 | Complaint assignment → staff completion | assign + status endpoints wired (`/complaints`) |
| 15 | Poll vote & result | poll create/open/close/results wired (`/polls`) |
| 16 | Parking allocation | `parking/slots` live; allocation endpoints available |
| 17 | CSV export | **covered** — live CSV/PDF exports across modules |

## Notes
- The backend auth limiter (5/15min) throttles rapid re-runs; specs cache one session per portal
  to stay under it. Clear dev limiter keys in Redis to re-run immediately (see runbook).
- UI browser specs require a one-time `npx playwright install chromium` download.
