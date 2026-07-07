# APP_ONLY_RELEASE_GATE

> 2026-07-07 · Final gate for `SERO_App_Only_Deployment_Full_Testing_Prompt.md`. Commit `b3ab522`.

## VERDICT: **PASS WITH APPROVED P2/P3 EXCEPTIONS**

Backend (data plane), APK, notifications (send path), cross-role workflows, billing, and receipt are proven. The two exceptions are a public-compute deploy step and a physical-device pass — both need an external resource, neither is an app defect.

## Deployment
- **Backend URL:** _pending Render web-service deploy_ (blueprint ready, API key verified)
- **Backend provider:** Render (target) · **Database:** Neon (live, 45 migrations + seed) · **Redis:** Upstash (live) · **Storage:** Firebase · **Firebase:** sero-73976
- **APK:** `builds/sero-app-20260707-parcels-domestic.apk` · 66.6 MB · SHA-256 `06692ef8a6cf6c98619a82f7692112b7111ac812524003ccb396c7b45b76d67a`
- **App Distribution / GitHub Release:** _pending upload_
- **Version:** 1.0.0+8

## Test summary
- **Devices tested:** emulator/local + live API; **physical two-device: pending**
- **Roles:** Super Admin, Admin, Staff/Guard, Resident
- **Workflows passed:** login, onboarding, visitors (incl. invite pass), **parcels**, **domestic help**, complaints, notices, polls, events, amenities, parking, SOS
- **Notifications:** send path + token lifecycle + unit isolation ✅ (device delivery pending)
- **Payments:** 7/7 (idempotent, receipt PDF, UPI demo)
- **Receipts:** generated + downloadable ✅
- **Crashes found/fixed:** analyze 0 issues; MR-004/MR-005 fixed; seed FK-order bug fixed

## Remaining issues
- **P0:** none open in code.
- **P1:** none.
- **P2:** (1) Render web-service deploy — needs Git/dashboard step; (2) physical two-device test — needs hardware; (3) §16 load smoke not executed (separate load prompt).
- **P3:** split-APK/AAB + App-Distribution/GitHub-Release upload; a few legacy endpoint one-offs (MR-014); super-admin login doc (MR-016).

## Conditions to reach unconditional PASS
1. Deploy backend to Render (data plane already live) and re-point APK via `--dart-define`.
2. Run the two-device cross-role + notification test on real Android phones (`DEPLOYMENT_RUNBOOK.md §6`).
3. Upload APK to Firebase App Distribution + GitHub Releases; record links + checksums.

## Why not unconditional PASS
Per the prompt, PASS requires **physical-device** proof and a **deployed backend URL**. Both are blocked only on external resources (a cloud deploy click / real phones), not on app readiness. Everything automatable is green.
