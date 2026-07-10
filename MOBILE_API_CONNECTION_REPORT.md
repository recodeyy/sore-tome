# Mobile API Connection Report — 2026-07-10

APK: `builds/sero-app-20260707-live-render.apk` (source lineage = render-live snapshot).

## Base URL audit (`sero/lib/config/env.dart`)
- `API_BASE_URL` default: `https://sero-api-live.onrender.com/api/v1` ✅
- `FALLBACK_URL`: same ✅
- No `localhost`, `10.0.2.2`, or GCP URL in release path (grep clean; overrides only via `--dart-define` for local dev).
- `auth_service.dart` strips `/api/v1` and calls root `/auth/*` — verified live: v1Router is double-mounted at `/` (legacy), so both paths work.

## Login contract
- App sends `{phone, password, portal?}` (auth_provider.dart / auth_service.dart) — matches backend Zod schema exactly.
- Login response consumed: `token`, `refreshToken`, `firebaseToken` (→ Firebase custom-token sign-in for Firestore rules), `activeWorkspace`, `destinations`, `requiresWorkspaceSelection`. All present in live response.

## Defects found & fixed
1. **15s hard timeout on every request** (`api_client.dart`) vs ~60s Render cold start ⇒ first request after idle ALWAYS timed out → login spinner/blank screens/“Something went wrong”. Fixed: on `TimeoutException`, ping `/health` with 75s timeout to wake the server, retry once with 30s timeout. (Server-side: keepalive workflow reduces sleeps.)
2. **/resident/* 403s** for Firestore-only memberships (see DATABASE_CONNECTION_REPORT) — resident Profile/Family/Vehicles/KYC/Emergency and parcels/domestic-help screens errored. Fixed server-side (self-heal membership).

## Rebuild required
The APK must be rebuilt to pick up fix (1): `cd sero && flutter build apk --release`. Fix (2) is server-side only — existing APK benefits immediately after backend deploy.

## Device-only checks still open (need physical device + adb)
- FCM foreground/background/killed delivery; token registration lifecycle.
- Per-role login walkthrough on device (resident/admin/staff/superadmin shells).
- `adb logcat` capture for any remaining screen-level exceptions.
