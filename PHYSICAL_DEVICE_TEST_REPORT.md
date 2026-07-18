# PHYSICAL_DEVICE_TEST_REPORT.md

**Date:** 2026-07-18 · **Device:** Vivo Y100 (V2239) over adb · **APK:** `sero-app-20260718-pay-receipts-fix.apk`
**Backend:** `sero-api-live.onrender.com` (deploy branch `render-live` @ `f82b95f`) · **Website:** `d79huy0uhwumb.cloudfront.net` (SST deploy 2026-07-18)
**Master source:** commits `69c2446` + `bfbc738`

Every ✅ below was demonstrated on the physical device or against the live production API this session, with screenshots in the session scratchpad.

---

## 1. Verified end-to-end on the device

| # | Flow | Result | Evidence |
|---|------|--------|----------|
| 1 | App launch → splash → dashboard | ✅ renders (blank-screen fixes live) | screenshots |
| 2 | Logout (drawer) → role landing | ✅ | UI dump |
| 3 | Resident login (`9876543200`, resident portal) | ✅ lands on dashboard with live data | "Good Evening Shiv" |
| 4 | Dues accuracy | ✅ ₹1875 (3 months) consistent on Home/Bills/Bill Details | previously always ₹0 |
| 5 | **Razorpay checkout (cards/netbanking/wallet/paylater)** | ✅ opens from Pay All & Pay Now | ₹1,875 checkout screenshot |
| 6 | **Full card payment** (domestic test Mastercard → mock Axis OTP) | ✅ "Payment Successful", id `pay_TExWORaDysRxjc` | success screen |
| 7 | Backend verify + recording | ✅ Payment History row ₹1875; dues recalculated ₹1875→₹1250 | UI dump |
| 8 | **Admin-created invoice → resident app** (website/API → app sync) | ✅ `INV-QA-20260718-001` appeared in Bills with Pay button; paid ₹1,250 via checkout | receipt RCPT-000001 |
| 9 | **Receipt generation & resident visibility** | ✅ `RCPT-000002` (₹625) listed in Receipts screen after the attribution fix deploy | app screenshot |
| 10 | **Receipt PDF download + preview + share** | ✅ authenticated PDF rendered in-app with print/share | PDF screenshot |
| 11 | **Notifications (in-app inbox)** | ✅ three live events: Dues reminder, New invoice, Payment received | inbox screenshot |
| 12 | **Dues reminder pipeline** | ✅ `reminders/run` → `notified: 1` (was **0** before the audience fix) → visible on device | API + inbox |
| 13 | Guard login (`guard`, staff portal) | ✅ Gate Console renders: shift check-in, Expected/Pending/Inside, quick actions | UI dump |
| 14 | Gate Console provider grid (§12: Swiggy/Zomato/BigBasket/Blinkit/Zepto/Courier/Cab/Vendor/…) | ✅ renders; Log Courier Entry form complete (name/phone/vehicle/purpose/flat) | screenshot |
| 15 | Visitor screens (My Visitors, Invite Visitor form) | ✅ render with clean empty states | screenshots |
| 16 | UPI QR (Demo) screen for invoice | ✅ renders QR + honest DEMO/TEST labeling and manual-verification notice | UI dump |

## 2. Verified against the live production API

- Admin login → create invoice → publish → **resident account fetches it** (records sync across roles through one backend).
- **Tenant privacy fix live**: `/funds/maintenance-status` now returns only the caller's own row to residents (previously the whole society's named dues roster).
- **Members backfill executed**: `POST /members-v2/sync-firestore` (new admin endpoint) inserted 3 / updated 2 for `hubtown-sunkist` — **app-registered residents (incl. the owner's account) now appear on the website's Members & Tenants**.
- Receipt attribution fix live: new payments record `created_by`; `GET /finance/receipts` returns the payer's own receipts.
- Guard credentials verified working (`guard`/`123456`, staff portal — seeded this session at the owner's request).
- Website serves the new bundle (no Google-Translate boot for English users; page reaches idle; owner confirmed dashboard + members page working).

## 3. Defects found & FIXED this session (all deployed)

1. **P0 blank screens** — 4 stacked causes (expired Firestore rules; missing composite indexes; navbar `Container(alignment:)` zero-height body; Render cold start). See `BLANK_SCREEN_CRASH_REPORT.md`.
2. **P0 Pay-flow dead end** — Pay Now led to a read-only screen with no pay action; wired to Razorpay checkout (`DuesCheckout`), invoices listed with per-invoice pay.
3. **P0 receipts invisible** — stub button ("no receipt endpoint") despite complete backend + `ReceiptsScreen`; wired everywhere (Bill Details, Bills quick link, More tile). Plus backend attribution fix (verify now carries the order intent's `createdBy` into payment+receipt; `listReceipts` matches receipts the caller personally paid).
4. **P0 dues always ₹0** — `residentBalanceProvider` matched users by display name and read a non-existent field; now delegates to the canonical dues provider.
5. **P0 society tenant split** — same society existed as `"HUBTOWN SUNKIST"` (residents) and `"hubtown-sunkist"` (admin/guard); users migrated + registration now joins existing spelling variants.
6. **P0 two user directories** — website reads Postgres `members`; app registration wrote only Firestore. Approvals now mirror into Postgres; `sync-firestore` endpoint backfills.
7. **P1 reminders reached nobody** — society-wide invoices (no member/unit) fanned out to zero recipients; now fall back to all approved residents. Proven: `notified 0 → 1`.
8. **P1 dues privacy leak** — any resident saw every resident's name/flat/amount owed; now scoped to self (management roles keep the full roster).
9. **P1 website hang** — Google Translate widget booted on every page and its resources hang; now lazy-loads only for non-English users.
10. **P2 deploy branch confusion** — Render deploys `render-live`, not `master`; both updated and documented.

## 4. Open gaps (not yet fixed — next work)

| Sev | Gap | Detail |
|-----|-----|--------|
| P1 | **Staff parcel/visitor → resident routing blocked by empty flats directory** | Gate Console's "Target flat" dropdown has no options in `demo-soc-1` (no units/flats seeded), so a courier entry cannot be assigned to a resident and the cross-role parcel→approval→notification journey cannot complete. Needs the §4 idempotent seed (wings/floors/flats + occupancies) or admin flats setup. |
| P1 | **FCM system-tray push unverified** | In-app inbox works; Android channels are registered (billing imp 4, visitors/SOS imp 5). But no SERO push banner was observed in the tray during the reminder test — device FCM token registration and the outbox→FCM sender need a dedicated test. |
| P2 | **Dual finance engines disagree** | Legacy Firestore dues (`/funds/maintenance-status`: ₹1250 outstanding) vs Postgres invoices (both settled). The §7.2 finance engine should become the single source and the legacy dues card should read from it. |
| P2 | Old receipt `RCPT-000001` invisible to the resident | Predates the attribution fix (`created_by` null, intent metadata without `createdBy`). Admin sees it; a one-row data repair or an admin reissue would restore resident visibility. |
| P2 | Razorpay "international card" rejection | The classic `4111…` Visa test card is rejected; domestic test card `5267 3181 8797 5449` works. Document for testers. |
| P2 | Pay center button top-half not tappable (OverflowBox visual outside hit area); browser automation blocked by a third-party Chrome extension ("Sailer") on the admin site — cosmetic/tooling issues. |
| P3 | Website Members list shows the owner's account twice (they registered two accounts; both migrated). Admin can deactivate one. |

## 5. Release-gate position (master prompt §21)

Resident billing lifecycle (bill → checkout → server verify → ledger → receipt → notification): **PASS** on the physical device.
Blank screens: **PASS**. Website/app record sync: **PASS** (invoice + members). Reminders: **PASS** (in-app).
Remaining automatic-fail items before a production release: staff→resident journey (needs flats seed), FCM tray delivery proof, single finance source of truth.
