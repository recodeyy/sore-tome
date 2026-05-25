# Launch Blockers Audit & Risk Matrices
**Date:** May 25, 2026  
**Scope:** Launch Blockers, Beta Obstacles, and Technical Debt Analysis  
**Mode:** Analysis Only

---

## 1. Top 10 Play Store Launch Blockers (P0 - Must Fix Before Release)

| # | Title | Description | Risk | Priority | Suggested Fix | Files Affected |
|---|---|---|---|---|---|---|
| 1 | Committed Firebase Secret Keys | The `serviceAccountKey.json` is committed in the active git repository. | **Critical** | P0 | Revoke old key in Firebase Developer Console, delete the local file, add to `.gitignore`, rewrite git history. | `society-backend/config/serviceAccountKey.json` |
| 2 | Hardcoded Debug Signing Configs | The Android build signs release compilations using debug keys. | **High** | P0 | Setup secure `key.properties` loading inside `build.gradle.kts` using environment keys. | `sero/android/app/build.gradle.kts` |
| 3 | Undeclared Android Permissions | `AndroidManifest.xml` lacks permissions for Camera, Audio, Notifications, and Media. | **Critical** | P0 | Add explicit `<uses-permission>` tags in the manifest for all imported hardware features. | `sero/android/app/src/main/AndroidManifest.xml` |
| 4 | Missing Play Store Reviewer Bypass | Reviewers cannot log in without a phone OTP and a live admin approval context. | **High** | P0 | Add a mock reviewer phone bypass that maps to a pre-approved demo society in the auth router. | `society-backend/routes/auth.js` |
| 5 | Missing In-App Account Deletion | No way for residents to delete their accounts, violating Google Play Data Safety policies. | **High** | P0 | Add a `DELETE /users/me` endpoint in backend and a "Delete Account" button in Flutter settings. | `society-backend/routes/users.js` |
| 6 | Unhandled Startup Network Offline Crashes | The splash screen crashes or freezes when launched without active network connections. | **High** | P0 | Wrap API calls inside startup providers with custom try/catch blocks that display offline cards. | `sero/lib/screens/shared/splash_screen.dart` |
| 7 | Webhook Signature Verification Fallback | The payments verification logs security warnings but lacks strict verification on failures. | **Medium** | P0 | Reject webhook requests immediately if HMAC verification signature comparison fails. | `society-backend/routes/funds.js` |
| 8 | Lack of Guard Role claim in Express Auth | Guard screens connect to APIs, but Express auth lacks validation for `guard` custom claims. | **Critical** | P0 | Update custom JWT claims logic to support the `guard` role and enforce it in `guardOnly` middleware. | `society-backend/middleware/auth.js` |
| 9 | Unpinned REST API Target Host | Flutter environment configs lack target safeguards, letting local envs target production hosts. | **High** | P0 | Enforce hard target profiles inside `env.dart` utilizing compile-time Dart defines (`--dart-define`). | `sero/lib/config/env.dart` |
| 10| Absence of Mobile Privacy Policy Link | No Privacy Policy links are present inside the mobile user dashboard or auth screens. | **High** | P0 | Add a support button in settings that launches the official Privacy Policy URL in a Webview. | `sero/lib/screens/shared/profile/profile_screen.dart` |

---

## 2. Top 10 Beta / Pilot Blockers (P1 - Must Fix Before Beta Launch)

| # | Title | Description | Risk | Priority | Suggested Fix | Files Affected |
|---|---|---|---|---|---|---|
| 1 | Mixed JS/TS Compilation Debt | Backend runs with on-the-fly TS compilation mixed with legacy JS routes. | **High** | P1 | Convert all remaining `.js` files to `.ts` and compile cleanly before shipping staging builds. | `society-backend/routes/*` |
| 2 | Double Tap Form Submission Debounce | Tap handlers lack locking, enabling residents to register duplicate flats concurrently. | **Medium** | P1 | Set state parameters (`isLoading = true`) during API triggers to disable buttons immediately. | `sero/lib/screens/shared/auth/register_screen.dart` |
| 3 | Postgres RLS Regression Test Absence | No automated unit tests exist to confirm that Row-Level Security blocks cross-society queries. | **High** | P1 | Add automated test suites that attempt to cross-query societies and assert RLS database rejections. | `society-backend/__tests__/rls.test.js` |
| 4 | Security Token Invalidation Sync | Role changes update claims, but active JWTs are not immediately blacklisted in Redis. | **High** | P1 | Sync revoked accounts immediately into a short-lived Redis token blacklist checked by middleware. | `society-backend/middleware/auth.js` |
| 5 | Guard Gate Offline Local Storage | If the gate has no network, guards cannot log entries, breaking daily society operations. | **High** | P1 | Cache visitor entries locally in the SQLite database and sync when connectivity returns. | `sero/lib/services/local_database_service.dart` |
| 6 | Manual Flat Entry Discrepancy | Residents type flat numbers as raw text, causing duplicates like "101" vs "F-101". | **Medium** | P1 | Replace raw text fields with dynamic dropdown lookups loaded from society flat rosters. | `sero/lib/screens/shared/auth/register_screen.dart` |
| 7 | Local Database Schema Upgrades | The SQLite local schema lacks version migration handlers, risking runtime crashes on upgrades. | **Medium** | P1 | Implement SQLite schema version upgrades inside the helper database initializer. | `sero/lib/services/local_database_service.dart` |
| 8 | Push Notification Service Unreliability | Background notifications do not render when the app is in the "Killed" operating state. | **High** | P1 | Configure background message handling hooks that call native Android Notification Builders. | `sero/lib/services/notification_service.dart` |
| 9 | Absolute Localhost SSRF Vulnerability | AI document ingestion URL checks reject localhost but ignore private subnet IPs (e.g. `192.168.*`). | **Medium** | P1 | Implement strict IP resolution parsing to block internal subnets and loopback addresses. | `society-backend/src/routes/ai.ts` |
| 10| Absence of Tenant Active Status Checks | Suspended societies can continue calling endpoints as long as their JWT tokens remain active. | **Medium** | P1 | Inject database checks inside the `tenantMiddleware` to block queries from suspended societies. | `society-backend/middleware/tenantMiddleware.ts` |

---

## 3. Top 10 Post-Launch Improvements (P2/P3 - Future Roadmap)

| # | Title | Description | Risk | Priority | Suggested Fix | Files Affected |
|---|---|---|---|---|---|---|
| 1 | Memory-based Rate Limiter Scaling | Rate limit states are held in Express memory rather than shared Redis clusters. | **Medium** | P2 | Reconfigure `express-rate-limit` to utilize the Redis engine as its centralized storage store. | `society-backend/server.js` |
| 2 | Firestore Ledger Scale Limitations | Long-term ledger histories in Firestore scale poorly and suffer from write hotspots. | **Medium** | P2 | Move historical ledgers to PostgreSQL tables using partitioned transactions. | `society-backend/routes/funds.js` |
| 3 | Real-time Chat Firestore Billing | Direct Firestore listener setups on every message channel scale billing excessively. | **Medium** | P2 | Shift active instant messaging chats to lightweight WebSockets or SSE streams. | `sero/lib/services/chat_service.dart` |
| 4 | Absence of Soft Deletes on Notice Boards | notices and issues are deleted permanently, removing audit histories. | **Low** | P2 | Implement `deletedAt` soft deletion parameters across notices and issues. | `society-backend/routes/notices.js` |
| 5 | Lack of SQL Connection Proxying | Horizontal auto-scaling of Express containers will exhaust Postgres connections. | **Medium** | P2 | Deploy PgBouncer in transaction pooling mode between Express and PostgreSQL. | `society-backend/src/shared/Database.ts` |
| 6 | PDF Service Local Storage Overhead | Generated payment PDFs are compiled locally on user devices, risking storage bloat. | **Low** | P3 | Delegate PDF processing tasks to a serverless lambda function that saves PDFs to cloud buckets. | `sero/lib/services/pdf_service.dart` |
| 7 | Custom Analytics Dashboard | No centralized reporting tools exist for administrators to monitor ledger and visitor data. | **Low** | P3 | Create a dedicated analytics module that queries aggregate trends from database summaries. | `society-backend/src/routes/admin_dashboard.ts` |
| 8 | Fuzzy Match Onboarding Optimizations | Whitelists rely on strict name mapping, leading to false negatives during onboarding. | **Low** | P3 | Integrate fuzzy match libraries (e.g. Jaro-Winkler) during registration checks. | `society-backend/routes/users.js` |
| 9 | Redis Outage Fallback Logic | Endpoints crash with 500 errors if the centralized Redis container goes offline. | **Medium** | P2 | Add fallback failover blocks inside cache drivers to handle Redis dropouts gracefully. | `society-backend/src/shared/Redis.ts` |
| 10| Standardized REST Error Serializer | Endpoint exceptions are returned using arbitrary schemas, causing parsing issues. | **Low** | P3 | Implement a global Express error response handler that standardizes response envelopes. | `society-backend/middleware/errorHandler.js` |
