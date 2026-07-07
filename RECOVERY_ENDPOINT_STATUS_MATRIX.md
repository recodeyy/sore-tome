# RECOVERY — Endpoint Status Matrix (live-probed)

> Generated from REAL HTTP probes against a backend booted from the recovery
> branch (`PORT=3010 npm start`, `http://localhost:3010/api/v1`).
> Date: 2026-06-25. Logins are the seeded test accounts (password `123456`).
> "scoped" = caller's JWT carries an active `society_id` (after the FIND-001 fix,
> single-workspace accounts auto-scope at login). "unscoped" = JWT `society_id=null`.

## Auth / login (POST /auth/login)

| Account (portal) | Status | requiresWorkspaceSelection | Notes |
|---|---|---|---|
| `admin` (admin) | 200 | **false** | 1 destination `admin-hubtown-sunmist`, JWT auto-scoped. Phantom `demo-soc-1` gone (FIND-001 fixed). |
| `9876543200` (resident) | 200 | false | Single resident workspace, auto-scoped. |
| `9000000001` (staff) | 200 | false | Single staff workspace. |
| `superadmin` (super-admin) | 200 | false | Platform workspace (`society_id=platform`); not society-guarded. |

## Society-scoped data endpoints

| Method | Path | Role | Scoped status | Unscoped status | Note |
|---|---|---|---|---|---|
| GET | `/admin/dashboard/summary` | admin | 200 | **409 NO_ACTIVE_WORKSPACE** | Real data: `openComplaints:2`, `staffOnDuty:3`. Guarded (FIND-002). |
| GET | `/admin/dashboard/vitals` | admin | 200 | 409 | Guarded. |
| GET | `/admin/dashboard/activity` | admin | 200 | 409 | Activity feed across domains. Guarded. |
| GET | `/notices-v2` | admin | 200 | 409 | Lists published notices. Guarded. |
| GET | `/notices-v2` | resident | 200 | — | Resident sees society notices. |
| GET | `/finance/invoices` | admin | 200 | 409 | INV-2026-001/002 present. Guarded. |
| GET | `/finance/reports/summary` | admin | 200 | 409 | `invoicedMinor:1180000, outstandingMinor:1180000`. Guarded. |
| GET | `/complaints` | admin | 200 | 409 | Admin sees all (CMP-001/002). Guarded. |
| GET | `/complaints` | resident | 200 (`[]`) | — | Correctly filtered to caller's own complaints. |
| GET | `/events-v2` | admin | 200 | 409 | Diwali + AGM events. Guarded. |
| POST | `/notices-v2` | admin | 201 | 409 | Creates draft (then `/:id/publish` → outbox + notifications, see flow below). |
| GET | `/structure/units` | admin | 200 | — | 7 units incl. A-1402; supports list/filter/pagination. |
| GET | `/amenities` | admin | 200 | — | Gym, Clubhouse, Pool, Community Hall. |
| GET | `/assets` | admin | 200 | — | Lift, Generator, Pump, CCTV. |
| GET | `/parking/slots` | admin | 200 | — | 4 slots seeded. |
| GET | `/staff-v2` | admin | 200 | — | Guard, Security Manager, Maintenance. |
| GET | `/members-v2` | admin | 200 | — | 5 members (admin/treasurer/secretary + 2 residents). |
| GET | `/polls-v2` | admin | 200 | — | Open poll w/ 3 options. |
| GET | `/society/profile` | admin | 200 | — | Hubtown Sunmist profile. |

> The 409 guard (`requireSociety`) is applied to: dashboard routes, `/notices-v2`,
> `/finance/*`, `/complaints`, `/events-v2`. Other society routes still rely on the
> pre-existing `tenantMiddleware` (403 on null society) and were left unchanged to
> keep the change minimal/reversible.

## Platform / unguarded (must NOT be society-gated)

| Method | Path | Role | Status | Note |
|---|---|---|---|---|
| GET | `/super-admin/societies` | super-admin | 200 | Platform route; null-society allowed. Not touched by the guard. |
| POST | `/auth/login` | (none) | 200 | Public auth. |

## No-auth / legacy

| Method | Path | Auth | Status | Note |
|---|---|---|---|---|
| GET | `/notices-v2` | none | 401 | Missing Authorization header. |
| GET | `/notices` (legacy) | admin | 200 (`[]`) | Firestore-backed; **logs `DEPRECATED legacy route hit — use v2`**. |
| GET | `/issues` (legacy) | admin | 200 (`[]`) | Firestore-backed; **logs deprecation warning**. |

## Notice publish flow (POST /notices-v2 → /:id/publish), verified in DB

| Side-effect table | Result |
|---|---|
| `notices` | 1 row, `status=published`. |
| `outbox_events` | 1 row `type=notice.published`, `topic=society:hubtown-sunmist` (drained by OutboxPublisher → `published=true`). |
| `notifications` | 1 row per approved member w/ a linked login, `type=notice`, `data.deepLink=sero://notices/<id>`. |
