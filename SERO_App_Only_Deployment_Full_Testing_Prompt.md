# SERO Mobile App-Only Deployment + Full Testing Master Prompt

## Role

Act as a Principal Mobile Release Engineer, Backend Deployment Engineer, Firebase/FCM Engineer, DevOps Engineer, QA Lead, and Society-App Product Tester.

You are working on the SERO repository:

https://github.com/recodeyy/sore-tome

The goal is to deploy and test the **mobile app only** with its required backend services. Do not include any website deployment, website testing, Admin website, Super Admin website, AWS website hosting, website routes, website dashboards, website exports, or website E2E flows in this task.

This prompt is only for:

- Android app APK/AAB release
- Backend API used by the mobile app
- Database used by the mobile app
- Redis/queues used by the mobile app
- File storage used by the mobile app
- Firebase Cloud Messaging push notifications
- Razorpay Test Mode payment demo
- Real Android device testing
- Cross-role mobile app testing for Super Admin, Admin, Staff/Guard, and Resident roles

Do not create another static demo. Do not only build an APK. The APK must connect to a deployed backend and prove the main society workflows end to end.

---

# 1. Best recommended mobile-app deployment

Use this deployment plan unless the repository proves a better option.

## 1.1 Mobile app distribution

Use:

- Firebase App Distribution for testers
- GitHub Releases as backup APK download
- Play Store later after final production readiness

Build outputs:

- Universal release APK
- Split APKs by ABI
- Android App Bundle

Required release artifacts:

- Universal APK path
- Split APK paths
- AAB path
- SHA-256 checksums
- Version name
- Version code
- Release notes
- Tester installation instructions

## 1.2 Backend API deployment for the app

Use Railway for fastest demo deployment if the backend already has a Dockerfile or can run with one clean start command.

Fallback order:

1. Railway
2. Render Web Service
3. Fly.io
4. AWS App Runner / Lightsail only if the team explicitly wants AWS for backend

The backend must expose:

- HTTPS API base URL
- Health endpoint
- Readiness endpoint
- Razorpay Test Mode webhook endpoint
- Realtime endpoint if using SSE/WebSocket
- Notification device-token endpoint
- File signed-upload/signed-download endpoints

Do not deploy to GCP.

Do not include website hosting in this prompt.

## 1.3 Database

Use Neon Postgres as the preferred free/low-cost Postgres database.

Fallback:

- Supabase Postgres
- Railway Postgres if keeping all backend resources in Railway is easier

Requirements:

- Run migrations automatically
- Seed mobile demo data
- Enable backups where available
- Use connection pooling where available
- Store `DATABASE_URL` only in environment variables/secrets

## 1.4 Redis and queues

Use Upstash Redis for:

- Rate limiting
- Notification deduplication
- Session/cache if needed
- Idempotency helpers

If BullMQ requires Redis features not supported by the selected Upstash plan, use Railway/Render Redis for demo and document the reason.

## 1.5 File storage

Use Cloudflare R2 as preferred free/low-cost object storage for:

- KYC files
- Complaint attachments
- Receipts
- NOCs
- Visitor/parcel photos
- Offline receipt downloads

Fallback:

- Supabase Storage
- AWS S3 only if already configured

All private files must use signed upload/download URLs. Do not use public buckets for private documents.

## 1.6 Notifications

Use Firebase Cloud Messaging.

Required:

- Android app registered in Firebase
- `google-services.json` correctly configured
- Backend Firebase Admin credentials stored as secrets
- Device token registration API
- In-app notification table
- Outbox/queue notification worker
- Foreground notification handling
- Background notification handling
- Killed-app notification tap handling
- Deep links to the correct app screen

## 1.7 AI providers for app

For demo:

- Gemini through backend only
- Groq through backend only
- No model key inside the mobile app
- AI disabled gracefully if keys are missing

## 1.8 Payment demo

Use Razorpay Test Mode only.

Rules:

- Backend creates Razorpay test order.
- Frontend opens Razorpay test checkout.
- Backend verifies signature/webhook.
- Receipt is generated only after backend verified status.
- UPI demo QR may be shown only as a demo/test option.
- Do not claim real bank settlement unless actually verified.
- Do not simulate payment success by changing a local frontend boolean.

---

# 2. Environment and secrets

Create:

- `.env.example`
- `APP_ONLY_DEPLOYMENT_ENV_MATRIX.md`
- `APP_ONLY_DEPLOYMENT_SECRETS_CHECKLIST.md`

Required environment variables:

- `NODE_ENV`
- `PORT`
- `API_BASE_URL`
- `DATABASE_URL`
- `REDIS_URL`
- `JWT_SECRET`
- `FIREBASE_PROJECT_ID`
- `FIREBASE_CLIENT_EMAIL`
- `FIREBASE_PRIVATE_KEY`
- `RAZORPAY_KEY_ID`
- `RAZORPAY_KEY_SECRET`
- `RAZORPAY_WEBHOOK_SECRET`
- `OBJECT_STORAGE_ENDPOINT`
- `OBJECT_STORAGE_BUCKET`
- `OBJECT_STORAGE_ACCESS_KEY_ID`
- `OBJECT_STORAGE_SECRET_ACCESS_KEY`
- `GEMINI_API_KEY`
- `GROQ_API_KEY`
- `APP_ENV`
- `APP_VERSION`

Never commit:

- Android keystore
- Keystore password
- Firebase private key
- Razorpay secret
- AI keys
- Database URL
- Redis URL
- Storage secret
- Production JWT secret

---

# 3. Deployment implementation steps

## Phase 0 — Clean baseline

1. Pull latest branch.
2. Record commit SHA.
3. Run backend install/build/tests.
4. Run Flutter clean/pub get/analyze/tests.
5. Record all current failures.
6. Do not hide failures.

## Phase 1 — Backend deploy

1. Add or fix Dockerfile.
2. Add health and readiness endpoints.
3. Add migration command.
4. Add seed command.
5. Deploy to Railway or selected backend provider.
6. Add environment secrets.
7. Run migrations.
8. Run Hubtown Sunkist demo seed.
9. Verify API health.
10. Verify database connection.
11. Verify Redis connection.
12. Verify storage connection.
13. Verify Firebase Admin connection.
14. Verify Razorpay Test Mode configuration.
15. Verify Gemini/Groq configuration if enabled.
16. Verify realtime endpoint if enabled.

## Phase 2 — Mobile release configuration

1. Set production/demo API base URL in the mobile app.
2. Configure Firebase Android.
3. Configure Android notification permissions.
4. Configure Android notification channels.
5. Configure deep links.
6. Configure app icon and splash.
7. Configure secure Android release signing.
8. Set version name and version code.
9. Remove localhost/dev URLs.
10. Remove mock/demo-only frontend fallback data.
11. Remove debug banners and test credentials.
12. Verify app talks only to the deployed backend URL.

## Phase 3 — Build and distribute

Run:

- `flutter clean`
- `flutter pub get`
- `dart format --set-exit-if-changed .`
- `flutter analyze`
- `flutter test`
- `flutter build apk --release`
- `flutter build apk --release --split-per-abi`
- `flutter build appbundle --release`

Then:

- Install APK on physical Android device.
- Upload APK to Firebase App Distribution.
- Upload APK to GitHub Releases as backup.
- Record download links and checksums.

---

# 4. Demo seed society

Create an idempotent backend seed for:

- Society: Hubtown Sunkist
- Wing: A
- Floor: 14
- Flat: 1402
- Resident owner for A-1402
- Admin
- Treasurer
- Secretary
- Guard
- Security manager
- Maintenance staff
- Domestic help
- Delivery visitor examples
- Maintenance bill
- Utility bill
- Notice
- Poll
- Event
- Complaint
- Parcel
- Parking slot
- Amenity
- Rule/bylaw document
- Receipt
- NOC request
- SOS test event

The seed must live in the deployed database. The app must fetch it through APIs. Do not hard-code demo data in Flutter.

---

# 5. Full mobile app testing outputs

Create:

- `APP_ONLY_DEPLOYMENT_REPORT.md`
- `APP_ONLY_FULL_TEST_REPORT.md`
- `APP_ONLY_NOTIFICATION_TEST_REPORT.md`
- `APP_ONLY_PAYMENT_TEST_REPORT.md`
- `APP_ONLY_CROSS_ROLE_SYNC_REPORT.md`
- `APP_ONLY_CRASH_FREE_REPORT.md`
- `APP_ONLY_RELEASE_GATE.md`
- `app_only_test_results.json`

For every test record:

- Test ID
- Role
- Device
- Build version
- Screen
- API endpoint
- Expected result
- Actual result
- Evidence
- Pass/fail
- Bug ID

---

# 6. Physical Android device testing

Test on at least two Android phones.

Phone 1:

- Resident A-1402

Phone 2:

- Admin or Guard

Optional Phone 3:

- Staff/Security

Test:

- Fresh install
- First login
- App restart
- App background
- App killed
- Poor network
- Logout/login
- Workspace switch
- Notification tap
- Deep link open
- APK upgrade over previous build

No release pass without physical-device testing.

---

# 7. Login and onboarding tests

Test:

1. Super Admin login.
2. Admin login.
3. Staff/Guard login.
4. Resident login.
5. Wrong-role login denial.
6. Pending resident state.
7. Resident requests Hubtown Sunkist A-1402.
8. Admin approves from mobile Admin shell if available, or backend/admin API if mobile Admin approval UI is not complete.
9. Resident receives notification.
10. Resident dashboard unlocks.
11. Suspended/rejected state.
12. Logout and token clearing.

Pass criteria:

- Correct shell opens.
- No wrong-role flash.
- No blank screen.
- No “Something went wrong.”
- Permissions match backend.
- Resident dashboard opens successfully.

---

# 8. Notification tests

Test FCM and in-app notifications for:

- Admin approval/rejection
- New bill
- Dues reminder
- Payment success
- Payment failure
- Receipt generated
- Visitor approval request
- Visitor entry
- Visitor exit
- Domestic help check-in
- Domestic help check-out
- Parcel received
- Parcel collected
- Complaint assigned
- Complaint status update
- Complaint chat message
- Notice published
- Poll opened
- Event created
- Amenity booking
- Parking allocation
- SOS triggered
- SOS acknowledged
- SOS resolved
- NOC update
- KYC update

For each notification verify:

- Backend event created
- Queue/outbox job created
- FCM sent
- Device receives notification in foreground
- Device receives notification in background
- Device receives notification when app is killed if supported
- Tap opens the correct app screen
- In-app notification appears
- Badge count updates
- Read/unread state works
- Wrong resident does not receive it
- Society B user does not receive it
- Duplicate notification is not sent

---

# 9. Visitor and gate-security tests

## 9.1 Staff sends delivery approval

1. Guard logs in.
2. Select society Hubtown Sunkist.
3. Select A Wing, Floor 14, Flat 1402.
4. Select visitor type:
   - Swiggy
   - Zomato
   - BigBasket
   - Blinkit
   - Zepto
   - Courier
   - Cab
   - Guest
   - Vendor
   - Service Provider
5. Enter name/mobile/purpose/photo if required.
6. Send approval request.
7. Resident receives push and in-app approval card.
8. Resident approves/rejects.
9. Guard sees result live.
10. Guard records entry.
11. Resident receives entry notification.
12. Guard records exit.
13. Resident receives exit notification.

## 9.2 Resident pre-invites visitor

1. Resident creates invite.
2. Visitor pass/QR/OTP is generated.
3. Guard sees expected visitor.
4. Guard scans/verifies.
5. Entry is recorded without unnecessary approval if policy allows.
6. Resident receives entry/exit update.

## 9.3 Domestic help

1. Admin or resident adds maid profile.
2. Schedule is configured.
3. Guard checks maid in.
4. Resident receives check-in notification.
5. Guard checks maid out.
6. Resident receives checkout notification.
7. Access history appears.

Pass criteria:

- Live sync works on two physical devices.
- No cross-flat leak.
- No duplicate active visitor entry.
- QR/OTP replay is blocked.

---

# 10. Billing and payment tests

Test:

1. Admin/Treasurer generates maintenance bill for A-1402.
2. Late fee appears if overdue.
3. Utility charges appear:
   - Electricity
   - Water
   - Maintenance
4. Resident receives bill notification.
5. Resident opens bill.
6. Resident sees line items.
7. Resident starts Razorpay Test Mode payment.
8. Backend creates order.
9. Frontend opens Razorpay checkout.
10. Payment success path.
11. Payment failure path.
12. Payment cancelled path.
13. Duplicate tap path.
14. App killed during payment.
15. Backend verifies webhook/signature.
16. UI shows processing until backend verification.
17. Receipt generated.
18. Receipt PDF downloads.
19. Offline saved receipt opens.
20. Admin/mobile summary updates if Admin mobile dashboard exists.
21. Duplicate webhook produces one financial effect.

Pass criteria:

- No local fake success.
- Ledger balances.
- Receipt matches payment.
- Resident and Admin data show same status.

---

# 11. Cross-role mobile sync tests

Test:

- Admin creates notice → Resident sees notice + notification.
- Admin creates poll → Resident votes → Admin result updates if Admin mobile poll view exists.
- Admin creates event → Resident RSVPs.
- Admin allocates parking → Resident sees slot.
- Admin configures amenity → Resident books.
- Admin updates rules/bylaws → Resident document updates.
- Admin approves NOC → Resident downloads certificate.
- Admin sends announcement → Resident receives push.
- Staff updates complaint → Resident receives update.
- Guard records visitor entry → Resident receives update.
- Guard records parcel → Resident receives update.
- Staff acknowledges SOS → Resident sees status.

If any Admin action is only available through backend/admin API for now, document it clearly and still prove the Resident app updates live.

---

# 12. Complaint workflow tests

1. Resident raises complaint with photo.
2. Admin sees complaint through mobile Admin flow or backend/admin API.
3. Admin assigns staff.
4. Staff gets notification.
5. Staff accepts.
6. Resident sees public status.
7. Staff uploads proof.
8. Admin verifies.
9. Resident receives resolution notification.
10. Resident rates or reopens.
11. Internal notes remain hidden from Resident.

---

# 13. Staff and parcel tests

Test:

- Staff attendance check-in.
- Staff attendance check-out.
- Staff roster visible.
- Staff leave request.
- Parcel logged for A-1402.
- Resident notified.
- Resident OTP/QR collection if supported.
- Staff handover.
- Resident sees collected status.

---

# 14. Amenities, parking, documents, SOS tests

Test:

- Amenity live slots.
- Resident booking.
- Double booking blocked.
- Cancel/reschedule if supported.
- Parking allocation.
- Vehicle registration.
- Parking violation notification.
- Rule/bylaw download.
- Receipt download.
- NOC request and approval.
- SOS trigger.
- Staff acknowledgement.
- Resolution timeline.

---

# 15. Crash-free and UX tests

For every app screen:

- Normal data
- Empty data
- Slow API
- 401
- 403
- 404
- 500
- Offline
- Bad/null field
- Unknown enum
- Deleted record
- Back navigation
- Refresh
- App background/resume

Pass criteria:

- No blank screen.
- No infinite loader.
- No unhandled exception.
- No generic “Something went wrong” without useful message and retry.
- No stack trace to user.
- No broken layout.
- No severe lag.
- Every error state has retry or clear next step.

---

# 16. Performance smoke tests

Run:

- 100-user smoke
- 500-user demo load
- Notification burst
- Visitor approval burst
- Bill generation burst
- Payment webhook duplicate burst

Check:

- p95 API latency
- Error rate
- DB connection count
- Redis health
- Queue depth
- FCM failure count
- App UI responsiveness
- No duplicate business effect

For demo release, do not claim 10K/20K unless the dedicated load-test prompt is executed.

---

# 17. Release gates

Automatic FAIL if:

- Backend is not deployed.
- APK connects to localhost.
- Any role cannot login.
- Resident dashboard crashes.
- Notifications fail on physical Android device.
- Visitor approval does not work live.
- Payment is locally simulated.
- Receipt cannot download.
- Admin action does not sync to Resident.
- Staff action does not sync to Resident/Admin.
- Wrong user receives notification.
- Any major screen is blank.
- Any major feature is mock-only.
- Secrets are committed.
- Database migrations fail.
- APK release signing fails.
- Flutter analyze/tests fail without documented approved exception.

---

# 18. Final response format from coding agent

At completion, return:

## Deployment

- Backend URL
- Backend provider
- Database provider
- Redis provider
- Storage provider
- Firebase project
- APK link
- Firebase App Distribution link
- GitHub Release link
- Version name/code

## Test summary

- Devices tested
- Roles tested
- Workflows passed
- Notifications passed
- Payments passed
- Receipts passed
- Crashes found/fixed

## Remaining issues

- P0
- P1
- P2
- P3

## Verdict

- PASS
- PASS WITH APPROVED P2/P3 EXCEPTIONS
- FAIL

Do not write PASS unless the deployed backend, APK, notifications, cross-role workflows, billing, receipt, and physical-device tests are proven.

---

# 19. Start instruction

Start in this exact order:

1. Pull latest repo.
2. Record commit SHA.
3. Run backend build/tests/migrations locally.
4. Run Flutter build/analyze/tests locally.
5. Deploy backend to Railway or selected provider.
6. Run migrations and Hubtown Sunkist seed.
7. Configure Firebase FCM.
8. Configure mobile app API base URL.
9. Build signed release APK.
10. Install APK on two physical Android phones.
11. Test notifications first.
12. Test visitor approval second.
13. Test billing/payment/receipt third.
14. Test all remaining cross-role workflows.
15. Generate final deployment and test reports.

Do not include website deployment or website testing in this task.
