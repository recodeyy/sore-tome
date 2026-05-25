# Privacy & Google Play Data Safety Audit
**Date:** May 25, 2026  
**Scope:** Data Collection, Play Store Data Safety Compliance, and Privacy Policies  
**Mode:** Analysis Only

---

## 1. User PII Data Collection & Mapping

### Current State
The app collects several categories of Personally Identifiable Information (PII) during registration and operations:
- **Residents:** Name, Phone Number, Password, Flat Number, Block Name, Profile Photo, and AI Chat messages.
- **Visitors:** Name, Phone Number, Target Flat, Vehicle Number, and Entry/Exit timestamps.
- **Admins:** Committee role, approvals log, and security event triggers.

### What is Good
- Passwords are never stored in plain text; they are hashed securely using Bcrypt (with 10 rounds) at the backend before being written to the database.
- Sensitive user records are isolated by `society_id` logically in Firestore and physically through RLS in PostgreSQL.

### What is Missing
- **Account & Data Deletion Flow:** There is no user interface in the mobile app, nor a backend endpoint, that allows a resident to delete their account or request full erasure of their personal details (such as deleting their phone log history).

### What Can Break
- **Play Store Rejection:** Google Play Policy strictly requires any app that allows account creation to also provide an in-app option and a web-based form for users to request account and data deletion. Submitting without this will lead to immediate rejection or removal.

### Real-World Risk
- **High:** App rejection from Google Play Store or account suspension.

### Priority
- **P0** (Must fix before Play Store launch)

### Recommended Fix
1. Create a `DELETE /users/me` endpoint in the backend that:
   - Sets the user status to `deleted`.
   - Scrubs their personal details (Name, Phone Number, Profile Photo) from active collections.
   - Clears all their active refresh tokens.
2. Build an "Account Deletion" button in the Flutter app profile screen (`profile_screen.dart`).
3. Set up a simple static web page with a form where users can submit account deletion requests externally.

### Files Affected
- `society-backend/routes/users.js`
- `sero/lib/screens/shared/profile/profile_screen.dart` (or settings screen)

---

## 2. Play Store Data Safety Form Draft

### Current State
No Data Safety declaration has been submitted. The app collects personal information, contact info, financial data (via Razorpay payments), and device/notification tokens.

### What is Good
- All data in transit is encrypted using HTTPS standard protocols when connecting to the API server and Firebase gateways.

### What is Missing
- **Data Safety Declaration:** A completed Google Play Data Safety Form draft is needed so the publisher can declare exact data practices during submission.

### What Can Break
- **Policy Violations:** Declaring incorrect data collection settings (e.g., claiming no financial info is processed when Razorpay is integrated) will trigger policy warnings from Google during manual reviews.

### Real-World Risk
- **Medium:** Release delays due to metadata policy corrections.

### Priority
- **P0** (Must compile before publishing)

### Recommended Fix
- Complete the Google Play Data Safety form inside the Play Console with the following exact values:
  - **Data Collected:** Personal Info (Name, Email, Phone, Address), Financial Info (Purchase History/Maintenance Paid), Photos, Device IDs.
  - **Data Shared:** None (Verify that third-party SDKs like Razorpay only receive data explicitly for transaction fulfillment).
  - **Data Security:** Declared as Encrypted in Transit (HTTPS).
  - **Account Deletion:** YES, users can request account and data deletion.

### Files Affected
- Play Store Console Metadata

---

## 3. Device Permissions & Privacy Controls

### Current State
The `AndroidManifest.xml` only requests the `<uses-permission android:name="android.permission.INTERNET"/>` permission.

### What is Good
- Minimal permission requests reduce the risk of malicious rating flags during automated security scanner inspections.

### What is Missing
- **Critical Android Permissions:** Hardware permissions (Camera for profile photos and visitor entry uploads, record audio for speech features, post notifications for push updates) are imported in the Flutter app but missing in the Android Manifest.

### What Can Break
- **Application Crash:** Attempting to call the image picker or speech engine on Android will crash the app instantly with a `SecurityException` since the OS blocks access to undeclared system hooks.

### Real-World Risk
- **High:** Critical app crashes during visitor registration, user registration, and push notification registrations.

### Priority
- **P0** (Must fix before Play Store launch or beta)

### Recommended Fix
- Insert the required permission tags inside `AndroidManifest.xml` and ensure that the Flutter app uses `permission_handler` to request permissions gracefully at runtime before firing native API wrappers:
  ```xml
  <uses-permission android:name="android.permission.CAMERA" />
  <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
  <uses-permission android:name="android.permission.RECORD_AUDIO" />
  ```

### Files Affected
- `sero/android/app/src/main/AndroidManifest.xml`
- `sero/lib/services/notification_service.dart`
