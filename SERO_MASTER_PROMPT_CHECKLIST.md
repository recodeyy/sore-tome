# SERO Master Prompt Execution Checklist

Source: `SERO_App_Full_Working_Billing_Visitor_AdminSync_Master_Prompt copy.md`
Started: 2026-07-18 · Commit at start: `18fd168` (master)
Status legend: ✅ done · 🔨 in progress · ⬜ pending · 🚫 blocked

---

## 0. Emergency fixes landed this session (pre-checklist)

These were found live on a physical device (Vivo Y100, V2239) before checklist work began:

- [x] ✅ **P0 — Blank screen after login (ALL resident/staff screens)** — 3 stacked root causes:
  - [x] Firestore **rules expired 2026-05-01** (test-mode rules deployed 2026-04-01) → every client denied since May. Deployed `society-backend/firestore.rules` to production (ruleset `8f26cd3b…`, old `943a992a…` kept for rollback). Verified: PERMISSION_DENIED gone.
  - [x] **Missing composite indexes** → deployed via `firebase deploy --only firestore:indexes` after adding 8 missing definitions (guest_passes ×2, pulses, bookings, ai_jobs, users, transactions, notifications) to `firestore.indexes.json`.
  - [x] **Navbar layout bug** (`premium_navbar.dart`: `Container(alignment:)` expands → Scaffold measured bottom bar as full-screen → body laid out at 0 height). Introduced in `debb3f5` (Jul 7) — the actual visible blank-screen cause for resident & staff shells on every device. Fixed; verified rendering on-device.
  - [x] Fixed APK: `builds/sero-app-20260718-blankscreen-navbar-fix.apk` — **distribute this to teammates**.
- [x] ✅ Verified live backend Razorpay = **TEST mode** (`rzp_test_…`, order creation 200 OK).

---

## §2 Mandatory audit

- [x] ✅ BLANK_SCREEN_CRASH_REPORT.md — written (4 stacked root causes, all fixed & device-verified)
- [ ] ⬜ APP_CURRENT_STATE_AUDIT.md (several older audits exist; need refresh against today's reality)
- [ ] ⬜ APP_SCREEN_ROUTE_API_MATRIX.md refresh
- [ ] ⬜ ADMIN_WEB_MOBILE_PARITY_MATRIX.md
- [ ] ⬜ CROSS_ROLE_WORKFLOW_MATRIX.md
- [ ] ⬜ BILLING_PAYMENT_RECEIPT_GAP_REPORT.md (findings below feed this)
- [ ] ⬜ VISITOR_STAFF_RESIDENT_GAP_REPORT.md
- [ ] ⬜ NOTIFICATION_GAP_REPORT.md
- [ ] ⬜ API_CONTRACT_REPORT.md
- [ ] ⬜ IMPLEMENTATION_SEQUENCE.md
- [ ] ⬜ app_recovery_findings.json / app_traceability.json

## §4 Demo society seed (Hubtown Sunkist A-1402)

- [x] Society "HUBTOWN SUNKIST" exists with resident Hardik Hinduja (A-1402, approved) — live account verified on device
- [ ] ⬜ Idempotent seed script covering all 11 test roles (super admin/main admin/treasurer/secretary/security manager/guard/maintenance/owner/family/other-flat/society-B)
- [ ] ⬜ Staff + guard accounts for Hubtown Sunkist (credentials unknown — LOGIN_CREDENTIALS_CHECKLIST.md rows 4–5 empty)

## §5 Resident dashboard recovery

- [x] Dashboard renders with live user/flat data (post-fix, on-device)
- [x] ✅ **Dues inconsistency FIXED**: `residentBalanceProvider` now delegates to `residentDuesProvider` (was name-matching + reading non-existent `amount` → always ₹0). Home, Treasury, and Bill Details read one canonical figure. In `sero-app-20260718-pay-receipts-fix.apk`; needs on-device re-verify after login refresh.
- [ ] ⬜ Payments/Documents tiles show "—" (must be live value or retryable error, never dash)
- [ ] ⬜ Live cards: due date, late fee, last payment, receipt available, parcels, domestic help, parking slot, active poll, latest notice, SOS
- [ ] ⬜ As-of time + deep link per card

## §6 Navigation cleanup

- [x] Resident bottom nav = Home/Community/Pay/Visitors/More ✓ (works after navbar fix)
- [x] More grid has Amenities/Parking/Parcels/Domestic Help/Documents/Rules/Family/Vehicles/Complaints/Profile ✓ renders
- [ ] ⬜ More lacks: KYC, Receipts, NOCs, Emergency Contacts, SOS
- [ ] ⬜ Audit drawer against required list; feature-flag "coming soon" items
- [ ] 🔨 **P2 — ₹ Pay center button top half not tappable** (OverflowBox visual extends above hit area)

## §7 Resident billing

- [x] ✅ **Pay flow dead end FIXED**: new `DuesCheckout` (per-screen Razorpay client, `payment_service.dart`) wired to Bill Details "Pay Now" and Bills&Dues "Pay All" — opens Razorpay TEST checkout (UPI/cards/netbanking) for the outstanding dues; verify posts to `/funds/payments/verify` with amount/title echo; providers + receipts refresh on success. Published §7.2 invoices also now listed on Bills&Dues with per-invoice Pay via existing `PayInvoiceSheet`. Needs on-device end-to-end test with a Razorpay test card/UPI.
- [ ] ⬜ Bills screen tabs (Outstanding/Upcoming/Paid/Overdue/All)
- [ ] ⬜ Bill fields (number, period, type, late fee, credits, outstanding, due date, invoice download)
- [ ] ⬜ Late-fee engine (server-side, configurable, audited)
- [ ] ⬜ Dues reminders (FCM schedule + dedupe)
- [ ] ⬜ Multiple bill types (maintenance/electricity/water/parking/amenity/penalty/…)

## §8 Payment flow (current: Razorpay TEST; prompt: UPI-intent)

- [x] Backend `/funds/payments/create-order` + `/finance/payments/create-order` work with **test keys** (`testMode:true`) — no fake success paths found in verify (HMAC + canonical amount fetch)
- [ ] 🔨 **P0 — App must reliably open Razorpay TEST checkout (UPI/cards) from Pay Now** (fix dead end above; wire §7.2 InvoiceCheckout or legacy PaymentService)
- [ ] ⬜ UPI payment-intent lifecycle (society VPA, dynamic QR, deep link, UTR submission, verification queue, states created→…→verified/rejected/expired) — backend + app + admin web
- [ ] ⬜ Never mark paid on client callback only (verify endpoint already enforces; extend to UPI intents)
- [ ] ⬜ Payment states machine + audit

## §9 Receipts

- [x] Backend endpoints EXIST: `GET /finance/receipts`, `GET /finance/receipts/:id/pdf` (finance.ts:124,142)
- [x] ✅ **App "Download Receipt" stub FIXED**: Bill Details button now opens the fully-built `ReceiptsScreen` (authenticated PDF download, in-app preview, share/print); "Receipts" quick-link added on Bills&Dues and a "Receipts" tile added to the More grid. Needs on-device verify after a captured payment exists.
- [ ] ⬜ Receipt generated only after verified payment (verify path exists; confirm receipt creation on verify)
- [ ] ⬜ Admin receipt register + void workflow
- [ ] ⬜ Receipt verification QR

## §10 Bank reconciliation

- [ ] ⬜ CSV import → auto-match (UTR/amount/date) → verification queue → ledger/receipt/notification
- [ ] ⬜ Idempotent import, duplicate UTR guards, audited overrides

## §11 Admin web ↔ mobile parity

- [x] 🔨 **Website hang root-caused & fixed in source**: the Google-Translate widget boots on EVERY page (`I18nProvider`); its `el_main` css/js requests hang `pending` forever → document never reaches idle. Fixed `src/lib/i18n/provider.tsx` to lazy-boot the widget only when a non-English language is active. **Needs website build + AWS redeploy** before website E2E can proceed.
- [x] ✅ Admin→resident record sync PROVEN at API level: admin (`demo-soc-1`) created invoice `INV-QA-20260718-001` (₹1250, Jul 2026) → published → resident account fetched it via `GET /finance/invoices?status=published` (200, same record). UI-level proof pending device/website.
- [x] ✅ **Society tenant split FIXED (owner-approved)**: resident accounts were in `"HUBTOWN SUNKIST"` while admin/guard were in `"hubtown-sunkist"` — cross-role sync structurally impossible for this society. Migrated 2 user docs to `hubtown-sunkist` (rollback field `society_id_premigration`). Registration now joins any existing spelling variant (`resolveSocietyId` in `routes/auth.js`) — **needs backend deploy to Render**.
- [ ] ⬜ Parity matrix (society/members, finance, communication, operations)
- [ ] ⬜ Website action → app update sync proofs

## §12 Visitors

- [x] Invite Visitor form renders (type chips, name, mobile, expected/valid-until, Generate Gate Pass)
- [x] My Visitors renders (clean empty state)
- [ ] ⬜ Full invite fields (people count, vehicle, purpose, single/multi entry, gate, notes)
- [ ] ⬜ Canonical pass + QR/OTP + staff expected list + entry/exit events + notifications (needs staff account to test)
- [ ] ⬜ Staff-created visitor → resident approval FCM → realtime staff update
- [ ] ⬜ Visitor state machine (expected/pending/approved/…/blocked)

## §13 Domestic help

- [ ] ⬜ Profiles, schedules, guard check-in/out, notifications, privacy across flats

## §14 Complaints

- [ ] ⬜ Raise → assign → staff accept → updates → verify → resolve → rate; internal notes hidden

## §15 Other cross-role workflows

- [ ] ⬜ Notice, poll, event, parking, amenity, parcel, SOS journeys (admin↔resident↔staff)

## §16 Notifications & realtime

- [ ] ⬜ Canonical NotificationService audit (FCM fg/bg/killed, dedupe, deep links, badge, token cleanup)
- [ ] ⬜ Delivery status + read state storage

## §17 API contract unification

- [x] Reproduced: dual payment paths (`/funds/payments/*` legacy vs `/finance/payments/*` §7.2) with different response shapes
- [ ] 🔨 **P1 — Privacy leak**: `/funds/maintenance-status` returns EVERY resident's dues to any resident (name, flat, amount). Must scope to caller (or admin-only for full list).
- [ ] ⬜ Canonical API per domain; typed DTOs; contract tests; OpenAPI

## §18 Zero blank screens

- [x] **Root causes fixed** (see §0). Verified on-device: home, treasury, bill details, invite visitor, my visitors, more grid all render.
- [x] Error-state audit start: streams use `.handleError((_) {})` (silent swallow) — providers can't distinguish empty from broken (feeds "dashes" problem)
- [ ] ⬜ Systematic screen matrix under: empty/null/slow/4xx/5xx/offline/expired-token/unknown-enum
- [ ] ⬜ Replace silent handleError with surfaced retryable error states

## §19 E2E journeys (website + 2 devices)

- [ ] 🚫 Blocked on: website login hang (§11), staff credentials (§4), phone battery (5% during session)
- [ ] ⬜ All 12 journeys with DB/API/realtime/notification/UI/audit proof

## §20 Tests

- [ ] ⬜ Backend suites (billing, UPI intent, dedupe, isolation) — existing tests in `society-backend/__tests__` need a run + gap list
- [ ] ⬜ Flutter widget/integration tests for dashboard/bills/receipts/visitors
- [ ] ⬜ Website tests (Playwright config exists: `sero-admin-web/playwright.config.ts`)

## §21 Release gate — current FAIL conditions still open

| Condition | Status |
|---|---|
| Resident billing incomplete | 🟡 fixed in code; on-device verify pending |
| Pay Now disconnected | 🟡 fixed in code (checkout wired); on-device verify pending |
| Receipt cannot download | 🟡 fixed in code (ReceiptsScreen wired); verify pending |
| Website/app payment status differs | 🟡 single dues source now; verify pending |
| Any major screen blank | 🟢 FIXED & device-verified |
| Cross-role sync possible for user's society | 🟡 tenant ids unified; journey test pending |
| Staff visitor ↔ resident | 🟡 untested (guard account exists in `hubtown-sunkist`; creds needed) |
| FCM on physical device | 🟡 untested |
| Tenant isolation | 🔴 `/funds/maintenance-status` returns all residents' dues to any resident |
| Website usable for E2E | 🟡 hang fixed in source; redeploy pending |

## §22 Deliverables

- [ ] ⬜ All 15 report files (release gate last)

---

## Execution order (prompt §23, adapted to today's reality)

1. [x] Record commit SHA (`18fd168`), device (Vivo Y100 V2239), backend (Render live)
2. [x] Reproduce blank screens → **fixed & verified**
3. [x] Reproduce broken billing + missing receipts → documented above
4. [ ] 🔨 **NEXT: unify dues source + connect Pay Now → Razorpay TEST checkout + wire receipt download** (P0 trio)
5. [ ] Fix website login hang (unblocks admin E2E)
6. [ ] Fix maintenance-status privacy leak
7. [ ] Staff account setup → visitor/parcel cross-role journeys
8. [ ] Notification audit on physical device
9. [ ] UPI-intent lifecycle (post-Razorpay-test decision with owner)
10. [ ] Parity matrix + remaining audits
11. [ ] E2E journeys + reports + release gate
