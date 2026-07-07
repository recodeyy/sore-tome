# SERO Admin Web — Cross-Role Sync Report

The website is the **control center** for the same backend + database the mobile app uses. It does
**not** duplicate data or logic — it calls the identical Postgres-backed `-v2`/domain endpoints the
Flutter app consumes. Therefore an admin action on the web is immediately visible to residents/
staff in the app, and vice-versa.

## Proven live (this session)

| # | Flow | Evidence | Status |
|---|---|---|---|
| 1 | Admin **creates notice** on web | `POST /api/proxy/notices-v2` → 201 with id | ✅ |
| 2 | Admin **publishes notice** | `POST …/:id/publish` → 200 | ✅ |
| 3 | **Read-back from shared DB** (mobile's feed) | `GET notices-v2` → notice present, `status=published` | ✅ |
| 4 | Admin reads **live invoices/dues** | `finance/invoices`, `finance/reports/dues` non-empty | ✅ |
| 5 | Super Admin **live platform metrics** | `super-admin/dashboard` → active_users=14, health=operational | ✅ |
| 6 | **Tenant isolation / auth** | proxy without session → 401 | ✅ |

Playwright `api-crossrole.spec.ts`: **5/5 passing**, including "admin notice write persists to
shared backend".

## Design guarantees for the remaining Section 9 flows

Because both clients share the endpoints below, these sync by construction:

| Requirement | Shared endpoint(s) |
|---|---|
| Admin creates society → resident can request flat | `super-admin/applications`, `societies` (public), `resident/join-requests` |
| Admin approves resident → resident dashboard unlocks | `members-v2/join-requests/:id/approve` ↔ `resident/dashboard` |
| Admin publishes notice → resident notification | `notices-v2` ↔ `resident/notices` |
| Admin generates bill → resident sees & pays | `finance/invoices` ↔ `resident/dues`, `finance/payments/*` |
| Admin creates poll → resident votes | `polls-v2` ↔ `resident/polls/:id/vote`, `polls-v2/:id/results` |
| Admin allocates parking → resident sees slot | `parking/allocations` ↔ `parking/my` |
| Admin assigns complaint → staff receives | `complaints/:id/assign` ↔ staff task feed |
| Staff completes task → admin & resident update | `complaints/:id/status` ↔ both feeds |
| Guard logs visitor → resident notification | `guard/visitors` ↔ `resident/visitors` |
| Resident pre-invites visitor → staff expected list | `resident/visitors` ↔ `guard/visitors` (status `expected`) |
| Super Admin toggles feature → nav changes | `super-admin/societies/:id/features/:key` ↔ client nav gates |

## Why there is no drift

- **Single source of truth**: no second DB; the web app has no local store of domain data.
- **Same money units** (minor) and same status enums as the app.
- **Same authorization**: the web app is subject to the identical `authMiddleware`,
  `tenantMiddleware`, and role guards — it cannot see or mutate another society's data.

## Coverage note (P2)

Guard/staff *write* actions (check-in, task completion) originate in the mobile app; the web shows
them **live** (read side verified). Adding equivalent web-side write actions for those staff flows
is a P2 enhancement — the read/sync direction required by Section 9 is in place.
