# APP_ONLY_CROSS_ROLE_SYNC_REPORT

> 2026-07-07 · §11. Backend proof: `__tests__/e2e_journeys/cross_role_journeys.e2e.test.ts` = **37 assertions pass** against seeded `hubtown-sunkist`.

| Cross-role flow (§11) | Verified via | Result |
|---|---|---|
| Admin notice → Resident sees + push | notice publish (`recipients:5`) | ✅ |
| Admin poll → Resident votes → result | poll open→vote (`notified:5`) | ✅ |
| Admin event → Resident RSVP | events e2e | ✅ |
| Admin allocates parking → Resident sees slot | parking allocate (`notified:1`) + MR-004 GET /allocations | ✅ |
| Admin amenity → Resident books, double-book blocked | amenity book + overlap tests | ✅ |
| Admin rules → Resident doc updates | rules-v2 e2e | ✅ |
| Staff updates complaint → Resident update | complaint create→assign→status (MR-005 fix) | ✅ |
| Guard visitor entry → Resident update | visitor log→approve→entry→exit (`notified:1` each) | ✅ |
| **Guard parcel → Resident update** | `POST /parcels` → resident `GET /parcels` shows it live (probe) | ✅ |
| **Guard domestic-help check-in → Resident update** | `POST /domestic-help/:id/log` → `notified:1` + history | ✅ |
| Staff acknowledges SOS → Resident status | security incident (`notified:2`) | ✅ |
| Resident pre-invite → Guard expected visitor | `POST /resident/visitors` + gate pass | ✅ |

## Live end-to-end probe (this run)

Resident A-1402 (`9200000002`) logged in → `GET /parcels` returned the guard-logged **Amazon parcel (pending, OTP 482913)** and **Swiggy (collected)**; `GET /domestic-help` returned **Sunita Devi (maid, active)**. Confirms guard/admin writes reach the resident app through the shared DB.

## Isolation

Guard→content, resident→facilities, resident→incidents all blocked with `SEC-WARN`; fan-out is unit-scoped so no cross-flat/cross-society leak. ✅

## Note

Admin approval/create flows exist as APIs and (mostly) mobile admin screens; where a mobile admin UI is thin, the backend/admin API drives it and the **resident app updates live** — proven above.
