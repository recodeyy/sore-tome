# SERO Deployment Connection, Website-App Sync, Blank-Screen, Render/AWS, and Full Error Testing Master Prompt

## Role

Act as a Principal Production Debugging Engineer, Full-Stack QA Lead, Render/Railway/AWS Deployment Engineer, Flutter Crash Debugger, React/Next.js Web QA Engineer, PostgreSQL/Neon Engineer, Firebase/FCM Engineer, and SRE.

You are working on the SERO repository:

https://github.com/recodeyy/sore-tome

The current system has serious deployment and connection problems:

- Local `.env` points to local dev PostgreSQL such as `localhost:5544`, but that database is not running.
- Production/staging database is likely Neon/Postgres and the real URL lives in Render/Railway/AWS environment variables.
- Some shell commands produce connection errors with empty messages.
- Some backend APIs work, some fail.
- Mobile app screens become blank after login.
- Website and app are not reliably connected.
- Admin website actions may not update the mobile app.
- Resident sections crash or show “Something went wrong.”
- Notifications may not fire.
- Render/AWS deployment may have environment, CORS, migration, API URL, secret, build, or runtime issues.
- The current repo may have mixed local/staging/production configs and broken API contracts.

Your task is to perform a complete deployment-connection and end-to-end testing audit, then produce exact fixes and verification evidence.

This is not a feature-building prompt. This is a production debugging, connection validation, and stability testing prompt.

---

# 1. Non-negotiable safety rule for secrets

Never print full secrets into logs, markdown reports, terminal output, screenshots, or commit history.

Mask:

- `DATABASE_URL`
- Render/Railway/AWS tokens
- Firebase private key
- Razorpay secret
- JWT secret
- Redis URL
- Storage secret
- AI provider keys
- Service-account JSON
- Neon password
- Any URL containing username/password

Allowed reporting format:

```text
DATABASE_URL = postgres://<user>:****@<host>/<db>?sslmode=require
REDIS_URL = rediss://****@<host>:6379
FIREBASE_PRIVATE_KEY = present, length valid, newline format valid
```

If a command accidentally prints a secret, stop and rotate it.

Do not paste production secrets into source code or `.env.example`.

---

# 2. Required final outputs

Create:

1. `DEPLOYMENT_CONNECTION_EXECUTIVE_SUMMARY.md`
2. `ENVIRONMENT_VARIABLE_AUDIT.md`
3. `LOCAL_VS_RENDER_VS_AWS_ENV_DIFF.md`
4. `DATABASE_CONNECTION_REPORT.md`
5. `MIGRATION_AND_SEED_STATUS_REPORT.md`
6. `BACKEND_API_HEALTH_REPORT.md`
7. `WEBSITE_API_CONNECTION_REPORT.md`
8. `MOBILE_API_CONNECTION_REPORT.md`
9. `BLANK_SCREEN_AFTER_LOGIN_REPORT.md`
10. `CORS_AND_NETWORK_REPORT.md`
11. `AUTH_WORKSPACE_ROLE_REPORT.md`
12. `WEBSITE_APP_SYNC_REPORT.md`
13. `NOTIFICATION_FCM_REPORT.md`
14. `RENDER_DEPLOYMENT_REPORT.md`
15. `AWS_WEBSITE_DEPLOYMENT_REPORT.md`
16. `ERROR_LOG_CORRELATION_REPORT.md`
17. `FULL_E2E_TEST_REPORT.md`
18. `DEPLOYMENT_FIX_PLAN.md`
19. `FINAL_DEPLOYMENT_RELEASE_GATE.md`
20. `deployment_test_results.json`
21. `deployment_findings.json`

Every finding must include:

- ID
- Severity: P0/P1/P2/P3
- Area: Env, Database, Migration, Backend, Website, Mobile, Auth, CORS, Notification, Render, AWS, Storage, Payment, AI
- Environment: Local, Render, AWS, Mobile release APK, Web production
- Reproduction steps
- Exact command/API/screen
- Expected
- Actual
- Root cause
- Fix
- Test to prove fix
- Evidence
- Status

---

# 3. First task: environment inventory

Before running random fixes, create a complete environment map.

## 3.1 Identify all environments

Document:

- Local backend
- Local Flutter app
- Local website
- Render backend
- Railway backend if used
- AWS website
- Firebase project
- Neon Postgres
- Redis provider
- Storage provider
- Razorpay Test Mode
- AI providers
- Domain/custom URLs
- APK build environment

## 3.2 Identify config files

Search for:

- `.env`
- `.env.local`
- `.env.production`
- `.env.staging`
- `.env.example`
- `render.yaml`
- `railway.json`
- `Dockerfile`
- `docker-compose.yml`
- `firebase.json`
- `google-services.json`
- `android/app/build.gradle`
- `pubspec.yaml`
- `next.config.*`
- `vite.config.*`
- API client config files
- Base URL constants
- CORS config
- Database config
- Migration scripts
- Seed scripts

Create a table:

| File | Purpose | Environment | Current value risk | Fix needed |
|---|---|---|---|---|

## 3.3 Required environment variables

Verify all required env vars exist in the real deployment provider, not only local `.env`.

Backend:

- `NODE_ENV`
- `PORT`
- `DATABASE_URL`
- `REDIS_URL`
- `JWT_SECRET`
- `CORS_ORIGINS`
- `PUBLIC_API_BASE_URL`
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
- `LOG_LEVEL`

Website:

- `NEXT_PUBLIC_API_BASE_URL` or `VITE_API_BASE_URL`
- `NEXT_PUBLIC_FIREBASE_*` if used
- `APP_ENV`
- `SENTRY_DSN` if used

Mobile:

- API base URL
- Firebase Android config
- Deep link host
- App environment
- Build flavor if used

For each variable report:

- Present/missing
- Valid format
- Environment
- Masked value
- Runtime availability
- Consumed by which file/module
- Failure if missing

---

# 4. Database connection testing

The local `.env` may point to `localhost:5544`. Treat local and production separately.

## 4.1 Local database

Test:

- Is local Postgres running?
- Is port correct?
- Is database created?
- Is user/password correct?
- Are migrations applied?
- Does backend start without DB?

Commands may include, adapted to repo:

```bash
docker compose ps
docker compose up -d postgres redis
npm run db:status
npm run migrate
npm run seed
```

Do not assume these exact commands exist. Inspect package scripts first.

## 4.2 Neon/production database

Test safely:

- Can Render backend connect to Neon?
- Is `sslmode=require` configured?
- Is connection pooling needed?
- Are migrations applied to Neon?
- Are tables present?
- Are required seed/demo rows present?
- Does Neon block connections due to IP/SSL?
- Does database schema match code expectations?

Use masked output only.

Create `DATABASE_CONNECTION_REPORT.md`.

Include:

- Local DB status
- Render DB status
- Neon status
- Migration version
- Missing tables
- Missing columns
- Missing indexes
- Failed queries
- Connection-pool issue
- SSL issue
- Correct fix

## 4.3 Migration verification

Run migration status against the same DB used by Render.

Verify tables/data for:

- Users/memberships
- Societies
- Units/flats
- Bills
- Payments
- Receipts
- Notices
- Polls
- Events
- Visitors
- Staff
- Complaints
- Notifications
- Device tokens
- Parking
- Amenities
- Documents
- AI conversations

If the mobile/website calls an endpoint and the table does not exist, mark P0.

---

# 5. Backend deployment testing on Render

## 5.1 Render service audit

Check:

- Service name
- Runtime
- Start command
- Build command
- Dockerfile
- Region
- Environment variables
- Health check path
- Auto-deploy branch
- Latest deploy status
- Latest commit SHA
- Build logs
- Runtime logs
- Crash/restart count
- Memory usage
- CPU usage
- Cold starts
- Timeouts

Create `RENDER_DEPLOYMENT_REPORT.md`.

## 5.2 Backend health tests

Test deployed backend:

```bash
curl -i https://<backend-url>/health
curl -i https://<backend-url>/ready
curl -i https://<backend-url>/api/health
```

Adapt to actual route names.

Readiness must check:

- Database
- Redis
- Storage
- Firebase Admin
- Queue worker
- Migrations

Health can be simpler.

If health passes but readiness fails, frontend should not be tested as production-ready.

## 5.3 Backend API smoke tests

For every API group test:

- Auth
- Workspaces
- Societies
- Members
- Resident approval
- Notices
- Polls
- Events
- Bills
- Payments
- Receipts
- Visitors
- Staff
- Complaints
- Notifications
- Parking
- Amenities
- Documents
- AI
- Files

Record:

- URL
- Method
- Auth required
- Response status
- Response shape
- Response time
- Error message
- Backend log correlation ID

No endpoint may return empty 500 with no useful message.

---

# 6. Website deployment and connection testing

The website must connect to the deployed backend API.

## 6.1 Website hosting audit

If website is deployed on AWS, verify:

- AWS service used: Amplify, S3 + CloudFront, App Runner, or other
- Build command
- Output directory
- Environment variables
- API base URL
- Domain
- HTTPS certificate
- CloudFront cache
- SPA fallback routing
- CORS with backend
- Latest deployed commit SHA

Create `AWS_WEBSITE_DEPLOYMENT_REPORT.md`.

## 6.2 Website API base URL test

Verify in built website bundle:

- It does not point to localhost.
- It does not point to expired GCP URL.
- It points to the correct Render/Railway backend.
- It uses HTTPS.
- It does not expose secrets.

Test in browser dev tools:

- Login request URL
- Dashboard request URL
- Notice creation request URL
- Bill creation request URL
- Poll creation request URL
- Visitor/security request URL
- Notification request URL

## 6.3 Website CORS test

From website origin, test:

- Preflight OPTIONS succeeds.
- Allowed methods include required methods.
- Allowed headers include Authorization and Content-Type.
- Credentials setting matches auth design.
- CORS does not allow `*` with credentials.
- Website production domain is allowlisted.
- Local dev domain is allowlisted only for non-production.

Document all CORS failures.

## 6.4 Website functional smoke tests

Test:

1. Login as Admin.
2. Load dashboard.
3. Create notice.
4. Create poll.
5. Generate maintenance bill.
6. Approve resident.
7. Assign complaint.
8. Allocate parking.
9. View payment report.
10. Send notification or announcement.
11. Logout.

For every failed screen, capture:

- Browser console error
- Network tab request/response
- Backend log
- Request ID
- Fix needed

---

# 7. Mobile app connection testing

## 7.1 Mobile API base URL audit

Verify the release APK uses correct API URL.

Check:

- Build flavor
- Dart define values
- Config file
- Environment service
- Any hard-coded localhost/GCP URL
- Any fallback URL
- Any cached old URL
- Any Firebase Remote Config if used

Fail if release APK calls:

- `localhost`
- `10.0.2.2`
- old GCP URL
- dev/staging accidentally when production expected
- production accidentally when staging expected

## 7.2 Mobile login and blank-screen reproduction

On physical Android device and emulator:

1. Install fresh APK.
2. Clear app data.
3. Open app.
4. Login as Resident.
5. Login as Admin.
6. Login as Staff/Guard.
7. Login as Super Admin.
8. Record blank screens.
9. Record “Something went wrong.”
10. Record infinite loaders.
11. Record crashes.
12. Capture logs with `adb logcat`.

For each blank screen identify:

- Route
- Role
- API request that failed
- Provider/notifier state
- Exception stack
- Null/JSON parse issue
- Missing route argument
- Missing workspace/society ID
- Missing table/field
- CORS/network issue
- Auth token issue
- Permission issue

Create `BLANK_SCREEN_AFTER_LOGIN_REPORT.md`.

## 7.3 Common causes to test

Check specifically for:

- Backend returns `societyId: null`
- Frontend expects `activeSocietyId`
- Workspace selection not persisted
- Invalid role mapping
- Admin route used for Resident
- Staff route missing shell
- API returns list where object expected
- API returns object where list expected
- Missing field causing model parse crash
- Unknown enum
- Date parse failure
- Amount parse failure
- Token refresh loop
- 401 hidden behind blank page
- 403 hidden behind blank page
- Provider never resolves loading state
- Stream subscription throws
- Widget uses `!` on nullable data
- Old cached workspace after logout
- Realtime connection fails and blocks UI
- Image/file URL null crash
- Notification permission prompt causing route issue

---

# 8. Website-to-app sync tests

Use two sessions:

- Browser: Admin website
- Phone 1: Resident app
- Phone 2: Staff/Guard app if available

Run all tests against the same deployed backend and same database.

## 8.1 Admin approval sync

1. Resident requests society/flat approval from app.
2. Admin sees request on website.
3. Admin approves.
4. Resident receives notification.
5. Resident dashboard unlocks.
6. Resident app shows correct society/flat.

## 8.2 Notice sync

1. Admin creates notice on website.
2. Resident receives push/in-app notification.
3. Resident notice board updates.
4. Tap opens notice detail.
5. Admin website read/ack report updates after resident opens.

## 8.3 Bill sync

1. Admin generates maintenance bill on website.
2. Resident receives notification.
3. Resident app shows bill and due amount.
4. Resident pays using Razorpay Test Mode.
5. Backend verifies payment.
6. Resident receipt appears.
7. Website payment report updates.
8. CSV/report export reflects payment if export exists.

## 8.4 Poll sync

1. Admin creates poll on website.
2. Resident app shows poll.
3. Resident votes once.
4. Website result updates.
5. Duplicate vote blocked.

## 8.5 Visitor sync

1. Guard app sends visitor approval for A-1402.
2. Resident app receives approval notification.
3. Resident approves.
4. Guard app updates live.
5. Website security dashboard updates if available.

## 8.6 Complaint sync

1. Resident creates complaint in app.
2. Admin website sees complaint.
3. Admin assigns Staff.
4. Staff app receives task.
5. Staff updates status.
6. Resident app updates.
7. Website status updates.

## 8.7 Parking sync

1. Admin allocates parking on website.
2. Resident app shows slot.
3. Resident receives notification.
4. Staff/Guard can verify vehicle/slot if available.

## 8.8 Amenity sync

1. Admin configures amenity/slot on website.
2. Resident app sees slot.
3. Resident books.
4. Website booking list updates.
5. Double booking blocked.

Create `WEBSITE_APP_SYNC_REPORT.md`.

Every sync must include:

- Source action
- Backend record
- Outbox/realtime event
- Notification event
- Destination UI update
- Test evidence

---

# 9. Notification and FCM debugging

Create `NOTIFICATION_FCM_REPORT.md`.

## 9.1 Device token registration

Verify:

- App requests permission.
- Token is generated.
- Token is sent to backend.
- Backend stores token with user ID, society/workspace if needed, platform, app version, device ID, and active status.
- Logout disables/removes token as designed.
- Multiple devices per user work.

## 9.2 Backend notification pipeline

Verify:

- Domain action creates outbox event.
- Worker picks event.
- Notification row created.
- FCM payload built.
- FCM send response logged.
- Invalid tokens are removed.
- Retry/backoff works.
- Deduplication works.

## 9.3 Physical device notification tests

Test foreground, background, killed app:

- Notice
- Bill
- Visitor approval
- Visitor entry/exit
- Complaint update
- Parcel
- Parking
- Poll
- Event
- Amenity
- SOS
- NOC/KYC

For each:

- Correct resident receives.
- Wrong resident does not.
- Society B does not.
- Tap opens correct route.
- In-app notification appears.
- Badge/read state updates.

---

# 10. Authentication, role, and workspace testing

Create `AUTH_WORKSPACE_ROLE_REPORT.md`.

Test:

- Super Admin
- Society Admin
- Treasurer
- Secretary
- Staff/Guard
- Resident owner
- Tenant
- Family member
- Multi-society user
- Pending resident
- Rejected resident
- Suspended resident
- Staff with no active assignment

Verify:

- Correct workspaces returned.
- Correct active society.
- Correct shell opens.
- Wrong role denied.
- Workspace switch clears state.
- Token refresh works.
- Logout clears tokens and cached state.
- Website and mobile agree on user identity and membership.

---

# 11. CORS, network, and SSL testing

Create `CORS_AND_NETWORK_REPORT.md`.

Test:

- Website origin → backend
- Local dev origin → backend staging
- Mobile app → backend
- Razorpay webhook → backend
- Firebase Admin → FCM
- Backend → Neon
- Backend → Redis
- Backend → storage
- Backend → AI providers

Verify:

- HTTPS works.
- Certificates valid.
- Mixed content not blocked.
- CORS preflight works.
- Authorization header allowed.
- Payload size limits sufficient.
- Timeouts clear.
- Backend does not crash on network failure.

---

# 12. Error logging and correlation

Add or verify request correlation IDs.

Every backend error should log:

- request ID
- route
- method
- user ID if known
- society ID if known
- status
- error code
- sanitized error message
- stack trace only in server logs
- duration

Every frontend error should show:

- user-friendly message
- retry
- request ID if available
- no raw stack trace

Create `ERROR_LOG_CORRELATION_REPORT.md`.

For every blank screen or 500 error, correlate:

- Mobile/browser error
- Network request
- Backend log
- Database query/log
- Root cause

---

# 13. API contract testing

Create automated contract tests.

For every frontend-used endpoint verify:

- Status code
- Response shape
- Required fields
- Nullable fields
- Enum values
- Date formats
- Amount formats
- Pagination
- Error shape
- Empty state shape

Critical endpoints:

- Login
- Session
- Workspaces
- Dashboard
- Societies
- Members
- Resident approvals
- Notices
- Bills
- Payments
- Receipts
- Polls
- Events
- Visitors
- Staff
- Complaints
- Notifications
- Parking
- Amenities
- Documents
- AI

Fail if website or app expects fields that backend does not send.

---

# 14. Crash-free UI requirements

Fix and test every app and website screen for:

- Normal data
- Empty data
- Null optional fields
- Unknown enum
- Slow API
- 401
- 403
- 404
- 409
- 422
- 429
- 500
- Offline/network loss
- Deleted record
- Permission revoked
- Token expired
- Workspace changed

Pass criteria:

- No blank screen.
- No infinite loader.
- No uncaught exception.
- No broken navigation.
- No silent failure.
- No fake fallback data.
- Clear retry or next step.

---

# 15. Full E2E test suite

Create `FULL_E2E_TEST_REPORT.md`.

Run the following against deployed environments:

1. Backend health/readiness.
2. Website login.
3. Mobile login.
4. Resident onboarding and approval.
5. Website notice → mobile resident notification.
6. Website bill → mobile resident payment → website report update.
7. Website poll → mobile vote → website result update.
8. Guard app visitor request → resident approval → guard update.
9. Resident complaint → website admin assignment → staff update → resident notification.
10. Parking allocation → resident mobile update.
11. Amenity creation → resident booking.
12. FCM foreground/background/killed app.
13. Receipt download.
14. File upload/download.
15. Logout/session expiry.
16. Wrong-role access denial.
17. Society B isolation.

---

# 16. Render/AWS deployment fix plan

Create `DEPLOYMENT_FIX_PLAN.md`.

Group fixes by:

## P0 immediate

Examples:

- Backend cannot connect to Neon.
- Migrations missing.
- Website points to localhost/GCP.
- Mobile points to localhost/GCP.
- Resident login blank screen.
- CORS blocks production website.
- FCM credentials invalid.
- Auth workspace null.

## P1 release blockers

Examples:

- Some features disconnected.
- Notifications missing for major workflows.
- Contract mismatch.
- Payment webhook broken.
- Route mismatch.
- Blank screens on secondary modules.

## P2 polish

Examples:

- Better error copy.
- Better loading state.
- Missing optional export.
- Non-critical chart.

For each fix include:

- File
- Env var
- Provider dashboard setting
- Command
- Test
- Owner
- Expected evidence

---

# 17. Final release gate

Release fails if:

- Backend cannot connect to correct deployed database.
- Render service is unhealthy.
- Website cannot reach backend.
- Mobile APK cannot reach backend.
- CORS blocks production website.
- Resident screen goes blank after login.
- Any core role cannot login.
- Workspaces are null/incorrect.
- Migrations are missing on deployed DB.
- Notifications fail on physical device.
- Admin website action does not update mobile app.
- Mobile action does not update website.
- Payment success is simulated locally.
- Receipt cannot download.
- Wrong resident receives notification/data.
- Any P0 remains.
- Any unapproved P1 remains.
- Secrets are printed or committed.

Final verdict must be:

- PASS
- PASS WITH APPROVED P2/P3 EXCEPTIONS
- FAIL

Do not mark PASS until the deployed website, deployed backend, deployed database, and release APK are tested together.

---

# 18. Start instruction

Start in this exact order:

1. Record current commit SHA.
2. Inventory local, Render, AWS, Firebase, Neon, Redis, and storage environments.
3. Mask and verify all environment variables.
4. Test deployed backend health/readiness.
5. Test database connection and migration status.
6. Test website API base URL and CORS.
7. Test mobile release API base URL.
8. Reproduce blank screen after login.
9. Correlate mobile/browser errors with backend logs.
10. Fix P0 environment and connection issues first.
11. Run website-to-app sync tests.
12. Run notification tests on physical Android devices.
13. Run full E2E suite.
14. Produce final release gate.

Do not start by changing UI. Fix environment, database, API contracts, auth/workspace context, and notifications first.
