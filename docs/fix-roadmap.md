# Staged Fix & Release Roadmap (90-Day Action Plan)
**Date:** May 25, 2026  
**Scope:** Action Plans, Engineering Allocation, and Timelines  
**Mode:** Analysis Only

---

## 1. Phase 1: Play Store Launch Hardening (Days 1 to 7)

### Current State
There are multiple P0 security and platform compliance issues, including committed credentials, hardcoded debug certificates, missing runtime hardware permissions, and lack of an account deletion flow.

### What is Good
- Core feature logics (payments, user registries, RAG chat tools) are fully developed, meaning this phase focuses purely on security adjustments and configuration corrections.

### What is Missing
- **A Structured Dev Allocation Checklist:** Standardized coordination tasks for the frontend and backend engineering teams are not formally outlined.

### What Can Break
- **Play Store Submission Denials:** Failing to implement these adjustments concurrently will lead to repeating cycles of Google Play Review rejections.

### Real-World Risk
- **High:** Delayed commercial launch, investor concern, and potential brand impact.

### Priority
- **P0** (Must complete immediately)

### Recommended Fix
- Deploy the following targeted adjustments within the week:
  1. **Security Lead:** Revoke the exposed Firebase service key, purge repository histories, and migrate configurations to secure environment variables.
  2. **Mobile Engineer:** Add camera, audio, and notification permission tags to `AndroidManifest.xml`.
  3. **Backend Engineer:** Implement a mock login route for the Google Play Review team and code the `DELETE /users/me` endpoint.
  4. **Mobile Engineer:** Implement the "Delete Account" button in settings and link the Privacy Policy to an in-app browser view.

### Files Affected
- `society-backend/config/serviceAccountKey.json`
- `sero/android/app/src/main/AndroidManifest.xml`
- `society-backend/routes/auth.js`
- `society-backend/routes/users.js`
- `sero/lib/screens/shared/profile/profile_screen.dart`

---

## 2. Phase 2: Beta Pilot Validation (Days 8 to 30)

### Current State
There are multiple P1 technical debts, including partial TypeScript integration, lack of input debouncing, missing automated RLS test suites, and lack of local offline databases for guards.

### What is Good
- Core business operations are functional under constant network states, facilitating isolated testing of components.

### What is Missing
- **Integration Test Pipelines:** There are no automated integration testing workflows configured.

### What Can Break
- **Gate Lockouts during Pilot:** Launching pilot testing inside housing societies without offline guard database syncs risks complete operational failure during network blackouts.

### Real-World Risk
- **High:** Loss of pilot clients, negative feedback from committee members, and product trust degradation.

### Priority
- **P1** (Must complete before pilot onboarding)

### Recommended Fix
- Allocate the following tasks for the first month:
  1. **Backend Architect:** Convert all remaining JS controllers in `/routes` and `/middleware` to TS.
  2. **QA Lead:** Implement Jest integration test suites checking registration rules and SQL Row-Level Security isolation.
  3. **Mobile Developer:** Code an offline SQLite sync queue in `local_database_service.dart` to save gate entries locally and push them asynchronously when online.
  4. **Frontend Developer:** Replace raw flat text fields with dropdown selects fetched from the roster database.

### Files Affected
- `society-backend/routes/*`
- `sero/lib/services/local_database_service.dart`
- `sero/lib/screens/shared/auth/register_screen.dart`
- `society-backend/__tests__/rls.test.js`

---

## 3. Phase 3: Post-Launch Scalability & Optimization (Days 31 to 90)

### Current State
Future roadmap items include Redis-based rate limit synchronization, migrating accounting ledgers to SQL, scaling chat protocols, and deploying connection pooling.

### What is Good
- The hybrid data models (NoSQL/SQL) are decoupled, allowing developers to optimize components independently without risking core system lockups.

### What is Missing
- **Telemetry and Performance Monitoring:** Database metrics and execution time analyzers are not integrated.

### What Can Break
- **System Slowdowns under High User Volumes:** As the active resident database grows to tens of thousands of users, unoptimized Firestore listens and lack of connection pools will cause scaling performance bottlenecks.

### Real-World Risk
- **Medium:** High cloud provider billing overhead and system lag during peak hours.

### Priority
- **P2 / P3** (Future roadmap)

### Recommended Fix
- Schedule the following structural refactorings for the second and third months:
  1. **DevOps Engineer:** Set up PgBouncer connection proxies and transition the memory-based rate limiter to Redis.
  2. **Database Architect:** Establish a migration plan to move long-term accounting records from Firestore to PostgreSQL.
  3. **Backend Developer:** Transition messaging channels from Firestore listens to lightweight SSE/WebSocket integrations to lower Firebase costs.

### Files Affected
- `society-backend/src/shared/Database.ts`
- `society-backend/server.js`
- `sero/lib/services/chat_service.dart`
