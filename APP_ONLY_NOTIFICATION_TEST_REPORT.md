# APP_ONLY_NOTIFICATION_TEST_REPORT

> 2026-07-07 · §8. Backend emit + token lifecycle verified; physical-handset delivery deferred to two-device test.

## Pipeline (verified)

Backend `device_tokens` (multi-device, UNIQUE token) ← `POST /notifications/devices` (+ legacy `PATCH /users/me`). Fan-out (`Recipients.fanOut`) inserts `notifications` rows **and** queues FCM push (`queuePush` → `notificationService.sendToUser` → `messaging().sendEachForMulticast`), pruning dead tokens on `registration-token-not-registered`/`invalid-*`. App: bg handler + 5 channels + deep-links (foreground/background/cold-start) + token-refresh re-register.

## Event coverage (backend emit points confirmed firing in e2e logs)

| Event | Emit verified | Recipient scope |
|---|---|---|
| Admin approval/rejection | ✅ | resident |
| New bill / dues reminder | ✅ (`payment_demo` dues once/day) | unit resident |
| Payment success / receipt | ✅ | resident |
| Visitor approval request / entry / exit | ✅ (`notified:1` each) | unit resident |
| **Domestic help check-in / check-out** | ✅ (`parcels_domestic` + live seed) | unit resident |
| **Parcel received / collected** | ✅ (`parcels_domestic` OTP flow) | unit resident |
| Complaint assigned / status | ✅ (`admins:1`, `notified:1`) | staff + resident |
| Notice published | ✅ (`recipients:5`) | audience |
| Poll opened | ✅ (`notified:5`) | eligible voters |
| Amenity booking | ✅ | resident + admin |
| Parking allocation | ✅ | resident |
| SOS triggered / acknowledged | ✅ (`notified:2`) | security + resident |

## Isolation (verified)

- Fan-out resolves **only the target unit's residents** (`unitResidentUserIds`) → wrong flat does not receive.
- All queries `society_id`-scoped → society B does not receive.
- Notification id derives from `message.messageId` → duplicate delivery dedupes.

## Not automatable here (documented)

Foreground/background/killed delivery on a real handset, notification-tap deep link on device, badge count, lock-screen privacy → **two-device physical test** (`DEPLOYMENT_RUNBOOK.md §6`). Everything up to and including the FCM `send()` call + token lifecycle is verified.
