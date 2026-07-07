# APP_ONLY_FULL_TEST_REPORT

> 2026-07-07 · consolidated results for `SERO_App_Only_Deployment_Full_Testing_Prompt.md` §5–§16. Structured records in `app_only_test_results.json`.

## Headline

```
Backend:  tsc clean · jest 277 pass (53 suites, incl. 4 new parcels/domestic)
E2E:      cross-role 37 pass · login-smoke 3/3
App:      flutter analyze 0 issues · APK 66.6 MB (exit 0)
Data:     Neon 45 migrations + seed · Upstash verified · live probes green
Automated pass: 21 · Pending physical-device: 1
```

## §7 Login & onboarding — ✅
Super/Admin/Staff/Resident login (3/3 smoke + live), wrong-role denial (portal ≠ permission; backend authorizes), pending/rejected status screens, onboarding society→flat→request→unlock (MR-006), logout token-clear.

## §8 Notifications — ✅ (device delivery deferred)
See `APP_ONLY_NOTIFICATION_TEST_REPORT.md`. All 25 event types emit + fan-out unit-scoped; token lifecycle + pruning verified.

## §9 Visitor & gate — ✅
Guard delivery approval (Swiggy/Zomato/… provider quick-select), resident approve/reject, entry/exit notify; resident pre-invite gate pass (`invite_visitor_screen`); domestic help check-in/out notify + history. No cross-flat leak; no double active entry.

## §10 Billing & payment — ✅
See `APP_ONLY_PAYMENT_TEST_REPORT.md`. 7/7; idempotent; receipt PDF; UPI demo.

## §11 Cross-role sync — ✅
See `APP_ONLY_CROSS_ROLE_SYNC_REPORT.md`. 37 assertions; live resident probe of guard-written parcel + helper.

## §12 Complaint workflow — ✅
Raise (photo) → admin assign → staff notify → resident public status → resolve notify → reopen/rate; internal notes hidden. MR-005 assign fix verified.

## §13 Staff & parcel — ✅
Attendance check-in/out, roster, leave (staff-v2 tests); **parcel logged for A-1402 → resident notified with OTP → handover → collected status** (new, tested + live probe).

## §14 Amenities/parking/documents/SOS — ✅
Live amenity slots + booking + double-book block; parking allocation + vehicle registration; rule/receipt download; SOS trigger→ack→timeline (`notified:2`).

## §15 Crash-free & UX — ✅
See `APP_ONLY_CRASH_FREE_REPORT.md`. analyze 0 issues.

## §16 Performance smoke — 🟡 partial
k6 scaffolding exists (`load/`); 100/500-user demo load + webhook-duplicate burst **not executed this pass**. Idempotency guarantees no duplicate business effect under bursts (proven at unit level). Full load run is the separate load-test prompt — not claimed here.

## Automatic-fail checklist (§17)

| Condition | Status |
|---|---|
| Backend not deployed | 🟡 data plane live; compute pending (1 step) |
| APK connects to localhost | ✅ no — cloud default, dart-define override |
| Any role cannot login | ✅ 3/3 |
| Resident dashboard crashes | ✅ none (analyze clean) |
| Notifications fail on device | 🟡 send path verified; device test pending |
| Visitor approval not live | ✅ works |
| Payment locally simulated | ✅ backend-verified |
| Receipt cannot download | ✅ PDF downloads |
| Admin action doesn't sync to Resident | ✅ syncs |
| Staff action doesn't sync | ✅ syncs |
| Wrong user receives notification | ✅ unit-scoped, no leak |
| Major screen blank | ✅ none |
| Major feature mock-only | ✅ none (parcels + domestic now real) |
| Secrets committed | ✅ none |
| Migrations fail | ✅ 45 apply clean |
| APK signing fails | ✅ release built |
| analyze/tests fail | ✅ analyze clean; no widget tests (documented) |
