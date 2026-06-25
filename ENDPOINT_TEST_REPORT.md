# SERO — Live Endpoint Test Report (Hubtown Sunmist)

**Date:** 2026-06-16
**Environment:** local dev — backend `:3001`, Postgres `:5544`, Redis `:6379`
**Test society:** `hubtown-sunmist` ("Hubtown Sunmist"), seeded via
`society-backend/scripts/seed_hubtown_sunmist.js`
**Auth:** Society Admin `admin` / `123456` (portal `admin`) → token scoped to
`society_id=hubtown-sunmist`.

> Method: provisioned one real, fully-linked society, logged in for a real scoped
> JWT, then hit each endpoint and recorded the live status. This is what surfaced
> the bugs below — none were visible until a real tenant token exercised them.

---

## A. Bugs found and fixed during this test pass

| # | Sev | Area | Symptom | Fix |
|---|-----|------|---------|-----|
| 1 | **P0** | Auth | `logger.alert is not a function` (`middleware/abuseProtection.js`) crashed requests with 500 | Added custom `alert` level to `src/shared/Logger.ts` |
| 2 | **P0** | Auth | Login wrote `undefined` `society_id` to Firestore → **every admin/super-admin (no society) got 500, could not log in** | Normalize `finalSocietyId` to `null` in `routes/auth.js` (both flows) |
| 3 | **P1** | Auth | Account with real Postgres membership also got a **phantom null-society workspace**, so the token never scoped → 403 on all data | Guard `addFirestoreDestinations` to only add a Firestore workspace when `user.society_id` exists |
| 4 | **P1** | Events | Client called `/events` (legacy Firestore, empty); Postgres events live at `/events-v2` | Repointed `events_provider.dart` to `/events-v2`; model accepts `starts_at` |
| 5 | **P1** | Amenities | No `GET /amenities` list route existed → client `getAmenities()` 404 | Added `BookingService.listAmenities` + `GET /amenities` route |

Also: seed data gap — `society_profiles` had **0 rows** (no society ever onboarded);
seeded Hubtown Sunmist (society, settings, 2 members, 3 notices, 2 events, 2 invoices,
2 complaints, 3 amenities).

---

## B. Admin portal — endpoint results (after fixes)

| Endpoint | Status | Notes |
|---|---|---|
| `GET /admin/dashboard/summary` | ✅ 200 | live aggregate |
| `GET /admin/dashboard/vitals` | ✅ 200 | tenant-scoped |
| `GET /notices-v2` | ✅ 200 | 3 notices |
| `GET /events-v2` | ✅ 200 | 2 events (was `/events` → empty) |
| `GET /finance/invoices` | ✅ 200 | 2 invoices |
| `GET /finance/reports/summary` | ✅ 200 | |
| `GET /finance/reports/dues` | ✅ 200 | |
| `GET /complaints` | ✅ 200 | 2 complaints |
| `GET /complaints/analytics` | ✅ 200 | |
| `GET /structure/summary` | ✅ 200 | |
| `GET /structure/units` | ✅ 200 | empty (none seeded) |
| `GET /society/profile` | ✅ 200 | |
| `GET /society/setup-progress` | ✅ 200 | |
| `GET /amenities` | ✅ 200 | 3 amenities (was 404) |
| `GET /parking/slots` | ✅ 200 | empty |
| `GET /assets/dashboard` | ✅ 200 | |
| `GET /staff-v2` | ✅ 200 | empty |
| `GET /reports/jobs` | ✅ 200 | |
| `GET /reports/templates` | ✅ 200 | |
| `GET /notifications` | ✅ 200 | |
| `GET /audit` | ✅ 200 | |

**Result: 21/21 admin endpoints return 200 with live tenant data.**

---

## C. Security behavior confirmed working (not bugs)

- **Abuse protection** auto-blocked the test IP after repeated 403s (`IP_BLOCKED`) —
  working as designed; loopback added to `ABUSE_WHITELIST` for testing only.
- **Login rate limiter** blocked further logins after many attempts
  ("try again after 15 minutes") — working as designed.
- **Tenant isolation**: a token with no `society_id` is rejected `403` by
  `tenantMiddleware` on every data route.

---

## D. Not yet re-verified (blocked or out of window)

| Item | Why | Next step |
|---|---|---|
| Resident portal endpoints | Login rate-limited (15 min) after admin test runs | Re-login `9876543200`/`123456` once window clears; member is seeded + linked |
| Staff / Security portal | No staff account seeded | Seed a `staff` row + Firestore login to test `/staff/*` |
| Super Admin portal | No `platform_users` account linked | Seed/confirm a `super_admin` account |
| Write actions (create notice/event, resolve complaint, book amenity) | Read pass done first | Exercise POST/PATCH with the scoped token |

---

## E. How to reproduce

```bash
cd society-backend
npm start                                   # backend on :3001 (PG+Redis up)
node scripts/seed_hubtown_sunmist.js        # seed the society
# login → scoped token → probe endpoints (see commands in this session)
```
</content>
