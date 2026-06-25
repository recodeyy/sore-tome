# SERO Android — APK Release Report

**Date:** 2026-06-16
**Engineer role:** Senior Flutter Release Engineer
**Flutter:** 3.44.1 (stable) • Dart bundled
**App:** `name: sero` • `version: 1.0.0+1` • `applicationId: sero.com`

---

## ❌ FINAL VERDICT: **FAIL — NOT READY FOR PRODUCTION RELEASE**

Per the release gate ("Do not mark the APK ready while any test fails, any page uses static data, any production service is disconnected, or any P0/P1 issue remains"), the build is blocked by multiple P0/P1 items below. No signed release artifact was produced because doing so would mislabel a non-releasable build as production-ready.

---

## Blocking issues (must be zero before release)

| # | Sev | Area | Evidence | Required fix |
|---|-----|------|----------|--------------|
| 1 | **P0** | Static/mock data | `lib/config/dev_config.dart:1` → `const bool kUseMockData = true;` | Complete backend cutover for ALL screens, then set `false`. Today only **2 modules** are wired to the real API (Admin Dashboard summary, Notices) — see `BACKEND_CUTOVER.md`. Flipping the flag now would break every un-migrated screen. |
| 2 | **P0** | Release signing | `android/app/build.gradle.kts:39` → release uses `signingConfigs.getByName("debug")`; no `android/key.properties`, no keystore | Create a release keystore (kept OUT of Git), add `key.properties` (git-ignored), and a real `release` signingConfig. |
| 3 | **P1** | Production config | `lib/config/env.dart` contains localhost/dev base URL | Point `apiBaseUrl` at the production `/api/v1` host via `--dart-define`; confirm Firebase, Razorpay, FCM, AI, deep-link configs are production values. |
| 4 | **P1** | Disconnected services | Most providers still read mock/Firestore (cutover incomplete) | Finish cutover: recommended order Finance → Complaints → Members → Amenities → Parking → Assets → Reports → Resident → Guard → Super-Admin. |
| 5 | **P2** | Lint hygiene | `flutter analyze` → **0 errors, 49 warnings, 42 info** (91 total): unused `api_service.dart` imports in `lib/services/admin/*`, unused locals, `use_build_context_synchronously`, deprecated `withOpacity`/`activeColor` | Clear warnings before release tag. |

---

## Steps performed

1. **Toolchain & static analysis** ✅ `flutter pub get` (ok; 63 deps have newer incompatible versions — non-blocking). `flutter analyze` → **0 errors, 49 warnings, 42 info**. Compiles cleanly.
2. **Config audit** ⚠️ `kUseMockData=true`; localhost in `env.dart`; release signing = debug. (Blockers 1–3.)
3. **Mock/secret scan** ⚠️ Mock layer active app-wide. Secret scan: no obvious committed secret inside `sero/lib` (backend service-account JSON lives at repo root, outside the app bundle — keep it git-ignored).
4. **Login routing** ⏳ Not device-verified. Backend role-portal validation is implemented and tested (`/auth` portal-mismatch → 403). Flutter shells for super_admin/admin/staff-guard/resident exist under `lib/screens/*`; end-to-end routing must be retested after cutover.
5. **App identity** ℹ️ name `sero`, id `sero.com`, version `1.0.0+1`, min/target SDK inherit Flutter defaults. Icon/splash/permissions not yet production-audited.
6. **Signing** ❌ Not configured (blocker 2). Keystore/passwords/`key.properties` must never be committed.
7. **Builds** ⛔ Not produced — prerequisites (signing, prod config, cutover) unmet. Commands to use once unblocked:
   - `flutter build apk --release`
   - `flutter build apk --release --split-per-abi`
   - `flutter build appbundle --release`
8. **Device install & live testing** ⛔ No physical device / live payment sandbox available in this environment.
9. **APK signature / size / network-security / secret scan of the package** ⛔ Pending a real build.

---

## Outputs

| Item | Value |
|---|---|
| APK path | — (not built) |
| Split APKs | — (not built) |
| AAB path | — (not built) |
| Version name / code | 1.0.0 / 1 |
| SHA-256 checksums | — (no artifact) |
| Unit/widget/golden tests | No Flutter test suite present under `sero/test`; backend suite = 267 passing (separate) |
| Signing verification | N/A (debug signing only) |

---

## Remediation checklist to reach PASS

1. Finish the Flutter→backend cutover for all remaining modules; remove mock fallbacks; set `kUseMockData=false`.
2. Set production `apiBaseUrl` + verify Firebase/Razorpay/FCM/AI/deep-link prod config.
3. Generate a release keystore; wire a `release` signingConfig via git-ignored `key.properties`.
4. Add a Flutter widget/golden/integration test suite; make it green.
5. Clear the 49 analyze warnings.
6. Audit icon, splash, permissions, `network_security_config`, version bump.
7. Build APK + split-ABI + AAB; verify signature (`apksigner verify`), size, min/target SDK, and that no debug endpoint/secret is in the package.
8. Install on a physical device; test login routing, payments, visitors, notifications, uploads, AI chatbot, offline, logout.
9. Re-run this report → only then mark **PASS**.

**Status: FAIL. Backend is production-ready and fully tested; the Android client is not, primarily because the mock→real cutover is only ~2 modules in and release signing/config are not set up.**
