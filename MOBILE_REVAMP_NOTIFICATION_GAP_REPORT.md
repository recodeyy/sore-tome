# MOBILE_REVAMP — Notification Gap Report

> Verified 2026-07-07 against local stack. This is the **root-cause analysis** for "notifications are not working reliably."

## 1. Root cause (P0): FCM token is never stored

The full chain, verified in code:

1. App: `AuthService.login()` (`sero/lib/services/auth_service.dart:63-67`) gets the FCM token and calls `updateFcmToken()`.
2. App: `updateFcmToken()` (`auth_service.dart:203-215`) sends `PATCH /users/me` with body `{fcmToken}`.
3. Backend: `routes/users.js:69` `PATCH /me` only whitelists `name|email|photoUrl`. `fcmToken` is ignored → `updates` empty → **400 "No editable fields supplied"**. The app swallows the 400 with a debugPrint.
4. Backend: `services/notificationService.js` `sendToUser()` reads `userData.fcmToken` from Firestore — which **nothing ever writes** → "User has no FCM token" → push silently skipped.

**Every push notification in the product fails at step 3.** Fixing this one endpoint restores the basic path.

## 2. Secondary gaps vs §10 requirements

| §10 requirement | Current state |
|---|---|
| One canonical NotificationService | App-side service is a 79-line stub (`notification_service.dart`); backend has `notificationService.js` (Firestore fcmToken) — single-token only |
| Multiple devices per user | ❌ single `fcmToken` field; needs `device_tokens` table (uid, token, platform, last_seen) |
| Remove invalid tokens | ❌ no cleanup on `messaging/registration-token-not-registered` |
| Foreground handling | ✅ `onMessage` → local notification |
| Background handling | ❌ no `onBackgroundMessage` top-level handler registered |
| Killed-app / tap deep link | ❌ `getInitialMessage`/`onMessageOpenedApp` not handled; tap handler only debugPrints payload |
| Android channels | ⚠️ single channel `sero_alerts`; no per-category channels (visitors/billing/notices/SOS) |
| Badge count | ❌ |
| Deduplication | ❌ no collapse keys / message ids |
| Retry/backoff, delivery logs | ❌ fire-and-forget, log-on-error only |
| Cross-society leakage | ⚠️ topic `society_{id}` exists but app never subscribes (`subscribeToTopic` has no callers) — so topics unused; per-user sends are scoped by uid (OK once tokens exist) |
| Lock-screen privacy | ❌ not configured |

## 3. Event coverage vs §10 matrix

Backend send-sites exist for some events (grep `sendToUser|sendToSocietyTopic`) but most §10 events have **no trigger wired**: visitor approval request/entry/exit, domestic-help in/out, parcels, dues reminder, payment result, amenity booking, parking allocation, SOS status, complaint chat. These must be added at the service layer (outbox → notification worker is the right seam — outbox events already exist for many domains).

## 4. Fix plan (Phase 3 of revamp)

1. **P0** Accept + persist tokens: new `POST /notifications/devices` (uid, token, platform, appVersion) backed by Postgres `device_tokens`; keep `PATCH /users/me` accepting `fcmToken` for backward compat with shipped APKs.
2. **P0** `sendToUser` reads all live tokens for uid; prunes invalid ones on send error.
3. **P1** Flutter: background handler, `onMessageOpenedApp` + `getInitialMessage` → route by `data.deeplink`; channels per category; re-register token on refresh (`onTokenRefresh`).
4. **P1** Wire §10 event triggers via outbox consumer (visitor/parcel/billing/complaint/SOS/amenity/parking).
5. **P2** Delivery log table + dedup keys + badge counts.
