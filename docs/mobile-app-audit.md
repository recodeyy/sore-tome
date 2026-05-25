# Mobile App Audit
**Date:** May 25, 2026  
**Scope:** Flutter/Dart Frontend, Mobile UX, and Device Offline Resilience  
**Mode:** Analysis Only

---

## 1. App Startup Flow & Crash Resilience

### Current State
The app startup decides initial routing inside `splash_screen.dart`. It loads tokens and user roles using Riverpod providers and reads persistent data from `FlutterSecureStorage`.

### What is Good
- Using Riverpod state management ensures that UI widgets automatically rebuild when state values change, preventing inconsistent UI render cycles.
- Storing JWT and refresh tokens in `FlutterSecureStorage` instead of plain SharedPreferences is secure and prevents token theft on standard devices.

### What is Missing
- **No Internet/Server Down Graceful Interceptors:** The startup sequence lacks a robust timeout/retry mechanism. If the server is offline or the user has a spotty cellular connection, raw `http` calls inside `auth_service.dart` or `api_client.dart` will throw unhandled `SocketException` or `TimeoutException`.

### What Can Break
- **App Freezes / Blank Screens:** When launching the app in a basement parking lot or near a gate with poor coverage, the splash screen loader will spin indefinitely or crash to a white screen, as there is no UI error card with a "Retry Connection" button.

### Real-World Risk
- **High:** High churn rates during the first 5 minutes of resident onboarding due to network dropouts.

### Priority
- **P0** (Must fix before Play Store launch)

### Recommended Fix
- Wrap all startup API calls inside Riverpod providers with robust try/catch blocks. If a network error is caught:
  1. Show a premium, custom "No Internet / Offline Mode" screen.
  2. Load cached dashboard data locally from the SQLite database to keep the app operational.

### Files Affected
- `sero/lib/screens/shared/splash_screen.dart`
- `sero/lib/services/api_client.dart`

---

## 2. Authentication & Onboarding validation

### Current State
Auth forms are managed across `login_screen.dart` and `register_screen.dart`. The register flow expects Flat Number and Block Name.

### What is Good
- Onboarding screens include text form validators that prevent blank or malformed submissions (e.g., checking if the phone has appropriate lengths and password inputs meet basic constraints).
- Immediate user status check blocks (`status: pending` or `status: rejected`) return clear, readable messages to the user during login.

### What is Missing
- **Double Tap Submission Debounce:** Submit buttons inside the authentication forms lack throttling or active state locking.
- **Flat Lookup Auto-Complete:** Residents must type their Flat Number manually as raw text, which leads to data naming discrepancies (e.g., "Flat 101", "F-101", "101" inside the same building).

### What Can Break
- **Duplicate Document Creation:** Tapping the submit button multiple times rapidly on a slow connection will trigger multiple concurrent `/register` HTTP requests, leading to database errors or duplicate notification pings on the admin dashboard.
- **Onboarding Chaos:** Text discrepancies in flat numbers prevent the billing ledger from correctly associating dues, leading to resident billing confusion.

### Real-World Risk
- **Medium:** User frustration and data mapping pollution in the flat Census database.

### Priority
- **P1** (Must fix before pilot launch)

### Recommended Fix
1. Disable submit buttons immediately upon click by setting a loading state parameter (`isLoading = true`) and checking it before firing API commands.
2. Replace the raw text input for flats with an auto-complete dropdown loaded dynamically from a pre-configured society Flat Roster API endpoint.

### Files Affected
- `sero/lib/screens/shared/auth/register_screen.dart`
- `sero/lib/screens/shared/auth/login_screen.dart`

---

## 3. Security Guard Flow & Offline Gate Resilience

### Current State
The security guard features are centered inside a single file `guard_home.dart`. It records visitor entries and checkouts, communicating with `/visitors/checkin` and `/visitors/:id/checkout` on the backend.

### What is Good
- The guard UI is streamlined, focusing on simple quick-action buttons suited for gate-level tablets.
- Real-time visitor approval push notifications are immediately sent to the target residents.

### What is Missing
- **Guard Session Offline Queueing:** The guard flow assumes constant high-speed internet. If the gate has no network, the app cannot log entries or checkout visitors, and lacks local offline databases for pending visitors.

### What Can Break
- **Gate Gatekeeping Failure:** If gate connectivity drops, guards will bypass the app entirely and use paper logs, causing the society dashboard to miss vital visitor security records and render the app useless.

### Real-World Risk
- **High:** Core product failure for societies, as visitor management is the primary daily utility of society apps.

### Priority
- **P0** (Must fix before onboarding any live pilot society)

### Recommended Fix
- Configure `cloud_firestore` offline persistence:
  ```dart
  FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
  ```
- Store all visitor check-in payloads inside local `sqflite` databases (`local_database_service.dart`) if the HTTP request fails. Run a background sync isolate that polls for network status and pushes queued entries to the backend once connectivity returns.

### Files Affected
- `sero/lib/screens/guard/guard_home.dart`
- `sero/lib/services/local_database_service.dart`
- `sero/lib/main.dart`
