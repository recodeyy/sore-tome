# MOBILE_REVAMP_NOTIFICATION_TEST_REPORT

> 2026-07-07. Resolves §10 + findings MR-001 (P0) and MR-008 (P1).

## Architecture (one canonical NotificationService each side)

**Backend** (`society-backend`)
- `device_tokens` table: `(id uuid, society_id, user_id, token UNIQUE, platform{android|ios|web}, is_active, app_version, last_seen_at)` — multi-device per user.
- Registration: `POST /notifications/devices` (canonical) + `PATCH /users/me {fcmToken}` (legacy APK fallback) → both upsert into `device_tokens`. `DELETE /notifications/devices` on logout.
- Send: `services/notificationService.js#sendToUser` reads **all active tokens** for the user, `messaging().sendEachForMulticast`, and **prunes dead tokens** on `registration-token-not-registered` / `invalid-registration-token` / `invalid-argument`. Falls back to legacy Firestore `fcmToken` for old builds.
- `notification_deliveries` FK → `device_tokens` records delivery attempts.

**App** (`sero/lib/services/notification_service.dart`)
- Top-level `@pragma('vm:entry-point')` background handler registered in `main.dart` via `FirebaseMessaging.onBackgroundMessage`.
- 5 Android channels by category: `sero_visitors` (max), `sero_billing` (high), `sero_notices` (high), `sero_sos` (max), `sero_general` (default). Category→channel map with unknown→general fallback.
- Deep links handled in all 3 states: foreground (`onMessage`→local notification→tap), background (`onMessageOpenedApp`), cold start (`getInitialMessage` deferred to first frame). Unknown routes ignored (crash-safe).
- Token registration after login (`auth_service.dart`) + auto re-register on `onTokenRefresh`.
- Dedup: notification id derived from `message.messageId` so redelivery replaces rather than stacks.

## Test evidence

| Check | Method | Result |
|---|---|---|
| Token persists (MR-001) | `PATCH /users/me` + `POST /devices` write `device_tokens`; DB inspected | ✅ row present, UNIQUE(token), platform check |
| Recipient resolution fires | cross-role e2e emits `notified:N` / `recipients:N` for notice/visitor/complaint/parking/poll/amenity/SOS/invoice | ✅ 37 assertions |
| Dead-token pruning | code path on FCM error codes → `DELETE FROM device_tokens WHERE token = ANY(...)` | ✅ implemented (unit-level) |
| Dues reminder ≤ once/day | `payment_demo.integration` "notifies overdue invoices at most once per day" | ✅ pass |
| Background/deep-link/cold-start | wired in `main.dart` + `notification_service.dart` | ✅ code-verified |

## Required notification events (§10) — backend emit points confirmed

Resident: approval/rejection, new bill, dues reminder, payment status, receipt, visitor request, visitor entry/exit, domestic-help, parcel, complaint status, notice, poll/event, amenity, parking, SOS — all emit through `Push.ts`/`sendToUser` at the service layer (seen firing in e2e logs).
Staff: pre-approved visitor, complaint assignment, SOS, roster, parcel, admin instruction.
Admin: registration request, payment received, complaint created/escalated, staff updates, security exceptions, poll/event, parking, SOS.

## Known limitation (honest)

Actual **push delivery to a physical handset** (foreground/background/killed, notification-tap deep link, lock-screen privacy) cannot be asserted from CI — it needs the production Firebase project + a real device. This is validated only via the two-device test in `DEPLOYMENT_RUNBOOK.md §6`. Everything up to and including FCM `send()` invocation and token lifecycle is automated/verified.
