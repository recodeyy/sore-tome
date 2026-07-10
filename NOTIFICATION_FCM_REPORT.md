# Notification / FCM Report — 2026-07-10

## Infrastructure verified (code + live indirect)
- Firebase Admin on Render: WORKING (login mints custom tokens; Firestore writes succeed) ⇒ FCM credential path is healthy.
- Device token pipeline exists: migration `20260707100000_device_tokens_mobile.js` (tokens with user/platform), mobile `notification_service.dart` registers tokens post-login; backend notifications rows + `/api/v1/notifications` 200 on live.
- Login response drives Firebase custom-token sign-in on mobile — required for Firestore-rule-gated realtime reads; token present in live login ⇒ realtime should authenticate.

## Physical-device tests: BLOCKED (require Android device)
Foreground/background/killed delivery for notice/bill/visitor/complaint/parcel/parking/poll/event/amenity/SOS, wrong-recipient isolation, tap-through routing, badge/read state — all need a device with the rebuilt APK. Test order:
1. Rebuild + install APK, login as resident, verify token row created (backend log or table).
2. From website as admin: create notice → expect push within seconds (foreground banner, background tray, killed tray).
3. Repeat per event type; verify Society-B account receives nothing.
4. Logout → verify token deactivated (no further pushes).

## Risks to watch
- Invalid-token cleanup and retry/backoff: implement/verify worker behavior in Render logs during the device test.
- If pushes fail only when app killed: check Android 13+ POST_NOTIFICATIONS permission prompt and OEM battery optimization.
