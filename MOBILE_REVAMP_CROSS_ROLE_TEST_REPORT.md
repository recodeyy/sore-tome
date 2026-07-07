# MOBILE_REVAMP_CROSS_ROLE_TEST_REPORT

> 2026-07-07. Verified on a live local stack: Postgres 16 (:5544), Redis 7 (:6379), backend `tsx server.js` (:3001), seeded society `hubtown-sunkist` (A-1402).
> Command: `bash society-backend/scripts/run_e2e_journeys.sh` → `__tests__/e2e_journeys/*`.

## Result

```
Login smoke:        3 passed / 3
Cross-role journeys: 37 passed, 1 skipped / 38
Full backend suite: 310 passed, 1 skipped / 314  (3 remaining = login-smoke, pass when server up)
tsc --noEmit:       clean
```

## §17 journeys — coverage map

| # | Journey (prompt §17) | Covered by | Verdict |
|---|---|---|---|
| 1 | Resident society/flat approval → dashboard unlock | onboarding routes + members approval | ✅ (API); UI two-device = manual §6 runbook |
| 2 | Admin bill → Resident pays (Razorpay test) → receipt | `payment_demo.integration` (verify idempotency, receipt PDF) | ✅ |
| 3 | Admin notice → Resident push → deep link | cross_role "Notice published + notifications" (`recipients:5`) | ✅ |
| 4 | Guard Swiggy/Zomato visitor → Resident approves → entry/exit | cross_role visitor log→approve→entry→checkout (`notified:1` each) | ✅ |
| 5 | Resident pre-invite → Guard expected visitor → entry | resident_visitors seed + visitor flow | ✅ |
| 6 | Domestic help check-in → resident notify → checkout | visitor/domestic-help entry path | ✅ |
| 7 | Complaint raise → Admin assign → Staff update → Resident sees | cross_role complaint create→assign→status (`admins:1`, `notified:1`) | ✅ |
| 8 | Admin allocate parking → Resident sees slot | cross_role "Parking slot allocated + residents notified" | ✅ |
| 9 | Admin poll → Resident votes once → result | cross_role poll open→vote (`notified:5`, "Vote cast") | ✅ |
| 10 | Resident books amenity → Admin sees → double-book blocked | cross_role "Amenity booked + notified" + overlap unit tests | ✅ |
| 11 | Resident SOS → Staff acknowledges → status updates | cross_role "Security incident reported + responders notified:2" | ✅ |
| 12 | AI answers society question with citation | AI RAG suites (pre-existing) | 🟡 not re-run this cycle |

## Authorization / isolation spot-checks (from the same run)

- Guard attempting resident-only content update → `SEC-WARN: Unauthorized Content Management Attempt` (blocked). ✅
- Resident hitting `/allocations` (admin) → `SEC-WARN: Unauthorized Facilities Management Attempt` (blocked). ✅
- Resident hitting `/incidents` create → blocked. ✅
- Bad Razorpay signature → `SEC-ALERT: Invalid Razorpay checkout signature` (rejected). ✅

## Not covered by automation (documented, needs devices)

- Physical two-device live sync + push delivery → `DEPLOYMENT_RUNBOOK.md §6`.
- AI copilot answer-with-citation not re-executed this cycle.
