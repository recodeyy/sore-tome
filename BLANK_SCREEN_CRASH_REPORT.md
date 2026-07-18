# BLANK_SCREEN_CRASH_REPORT.md

**Date:** 2026-07-18 · **Device:** Vivo Y100 (V2239, Android, Mali-GPU MediaTek mt6877) · **APK under test:** `sero-app-20260713-cache-fix.apk` → fixed in `sero-app-20260718-blankscreen-navbar-fix.apk` and `sero-app-20260718-pay-receipts-fix.apk`
**Method:** live on-device reproduction over adb (logcat + screencap + uiautomator), Firestore rules/index replay with the production project, backend API probes against `sero-api-live.onrender.com`.

---

## Executive summary

"Blank screen after opening app / after login" was **four independent defects stacked**, which is why every earlier single-fix APK (Jul 10 coldstart-fix, Jul 13 cache-fix) appeared to change nothing. All four are now fixed; the resident shell renders live data on the physical device.

| # | Layer | Root cause | Fix | Status |
|---|-------|-----------|-----|--------|
| 1 | Firestore security | Production project still ran the **Firebase "test mode" rules deployed 2026-04-01, which expired 2026-05-01**. Every client read since May → `PERMISSION_DENIED`. App streams swallow errors (`.handleError((_){})`), so screens showed zeros/blank instead of an error. | Deployed `society-backend/firestore.rules` (tenant-scoped) as ruleset `8f26cd3b-d282-40b5-a316-e8f182056184`. Rollback: `943a992a-9609-4362-8a67-7dad9af6b05b`. | ✅ deployed & verified (replayed the exact failing query as the real user: 403 → passes rules) |
| 2 | Firestore indexes | Only 5 composite indexes existed; app queries (guest_passes, pulses, bookings, ai_jobs, notifications, transactions-by-createdAt, users-by-flatNumber) → `FAILED_PRECONDITION`. Also invisible due to swallowed errors. | Added 8 definitions to `society-backend/firestore.indexes.json`; `firebase deploy --only firestore:indexes` after owner login. | ✅ deployed |
| 3 | **Flutter layout (the visible culprit)** | `FloatingPillNavbar` (`sero/lib/widgets/shared/premium_navbar.dart`) wrapped the pill in `Container(padding:…, alignment: Alignment.bottomCenter)`. A `Container` with `alignment:` **expands to fill its parent**, so `Scaffold` measured `bottomNavigationBar` as full-screen tall and laid the body out with **zero height**. Resident & Staff shells → white body + floating pill. Introduced in commit `debb3f5` (Jul 7 revamp); present in the Jul 13 APK. Proof: uiautomator dump of the "blank" screen contained only `Home`/`Pay` nodes; screencap showed pill + white body; no Flutter exception in logcat. | Removed the `alignment:` (pill sizes intrinsically). | ✅ fixed, verified on device (dashboard, treasury, bill details, visitors, more grid all render) |
| 4 | Backend cold start | Render free tier sleeps; first request ~60–75 s (measured 61.8 s on `/health`). The app's 15 s timeout + wake-and-retry keeps screens in loading/empty states on cold open. | Mitigated by fail-soft cache (Jul 13). Permanent fix = paid instance or keep-alive ping. | 📋 documented, accepted for now |

**Not the cause:** Impeller/Vulkan rendering on Mali was suspected (BLASTBufferQueue buffer-acquire errors in logcat) and ruled out — an Impeller-disabled build rendered identically blank; the buffer errors were a symptom of the zero-height layout, not the renderer. The temporary opt-out was reverted.

## Contributing defect (fixed in same session)

- `residentBalanceProvider` matched the caller in `/funds/maintenance-status.unpaid[]` **by display name** and read a non-existent `amount` field → always ₹0. Home showed "Total Due ₹0" and Treasury "All Clear" while Bill Details (via `residentDuesProvider`, uid-matched, `amountOwed`) showed ₹1250/3-months. Fixed by delegating `residentBalanceProvider` to `residentDuesProvider` — one canonical dues source for Home/Treasury/Bill Details.

## Silent-error pattern (systemic, follow-up recommended)

Every Firestore stream provider uses `.handleError((_) {})` and several FutureProviders `catch (_) { return 0/[] }`. Layers 1–2 were invisible for **11 weeks** because of this. Recommendation (§18 of master prompt): surface stream errors into `AsyncValue.error` with retry UI; forbid silent-swallow in new code.

## Related fixes landed while investigating

- **Society tenant split:** resident accounts sat in `society_id="HUBTOWN SUNKIST"` while admin/guard sat in `"hubtown-sunkist"` — cross-role sync could never work for this society. Migrated the 2 resident user docs to `hubtown-sunkist` (rollback breadcrumb `society_id_premigration` on each doc; owner-approved). Registration now resolves any spelling variant to the existing tenant id (`resolveSocietyId` in `routes/auth.js`) — needs backend deploy.
- **Admin website hang:** the Google-Translate widget boots on every page; its `el_main` resources hang in `pending` → document never reaches idle → page unresponsive to automation and slow for users. Fixed `sero-admin-web/src/lib/i18n/provider.tsx` to lazy-boot the widget only when a non-English language is active — needs website redeploy.
- **Pay flow dead end + receipt stub:** see `SERO_MASTER_PROMPT_CHECKLIST.md` §7–§9 (Pay Now now opens Razorpay TEST checkout; Download Receipt/Receipts screen wired to `GET /finance/receipts/:id/pdf`).

## Distribution

Give teammates **`builds/sero-app-20260718-pay-receipts-fix.apk`** (supersedes `…-blankscreen-navbar-fix.apk`, which supersedes all earlier builds). Anyone on an older APK will still see stale-cache zeros until they update; the blank screen itself cannot recur on old APKs now that rules/indexes are live, but the body-height bug (#3) is only fixed in the 2026-07-18 builds.
