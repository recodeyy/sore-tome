# Play Store Launch Analysis: Sero & Society Backend
**Date:** May 25, 2026  
**Scope:** Android/Flutter Build & Play Store Policy Auditing  
**Mode:** Analysis Only

---

## 1. Executive Summary & Google Play Compliance

### Current State
The mobile frontend is a Flutter app (located in `/sero`) targeting Android and iOS, with custom configurations defined in `build.gradle.kts` and `AndroidManifest.xml`. Backend services are managed under `/society-backend` utilizing Express and Firebase.

### What is Good
- The Android project uses a modern Gradle configuration (`build.gradle.kts` in Kotlin DSL) which keeps build files cleaner and more maintainable than legacy Groovy scripts.
- Firebase integration is structured, with `google-services.json` already present in the `/android/app` folder, matching the package name `sero.com`.
- Minimal permissions are currently requested in the `AndroidManifest.xml`, reducing initial friction during automated Google Play compliance scans.

### What is Missing
- **Permissions Mismatch:** Though `pubspec.yaml` imports packages that require local hardware permissions (e.g., `image_picker` requires camera/storage, `speech_to_text` requires audio recording, `firebase_messaging` requires notification permissions, and `razorpay_flutter` might need phone status checks), **none** of these permissions (except `INTERNET`) are declared in the `AndroidManifest.xml`.
- **Release Signing Configurations:** The `build.gradle.kts` file hardcodes the release build to sign with the debug key (`signingConfig = signingConfigs.getByName("debug")`).
- **Play Store Privacy Policy Linkage:** There is no in-app settings screen containing privacy policies or support links.

### What Can Break
- **Runtime Crashes:** Any flow utilizing images (e.g., visitor logs, user profiles, OCR receipts), notifications, or voice commands will crash instantly at runtime because Android will throw a `SecurityException` when these packages try to access hardware API hooks that are not requested in the Manifest.
- **Play Store Rejection:** Submitting a release APK or AAB signed with a debug certificate will be immediately rejected by the Google Play Console validator.
- **Policy Violations:** Google Play strictly requires apps that collect PII (phone number, name, apartment unit numbers) to have an accessible Privacy Policy in the Play Store listing and within the app itself. Failure to do so will lead to app removal or account suspension.

### Real-World Risk
- **Critical:** Complete app instability on user devices, leading to 1-star reviews on day one, and immediate automated rejection by Google Play Console during build upload.

### Priority
- **P0** (Must fix before Play Store launch)

### Recommended Fix
1. Add explicit permissions in `/sero/android/app/src/main/AndroidManifest.xml` for all imported features:
   ```xml
   <uses-permission android:name="android.permission.CAMERA"/>
   <uses-permission android:name="android.permission.RECORD_AUDIO"/>
   <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
   <uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
   ```
2. Configure a secure `signingConfigs` block inside `build.gradle.kts` using environment variables or a secure local `key.properties` file loaded at compile time (never commit keystores or keystore passwords to git).
3. Set up a static hosting page for the Society App Privacy Policy and direct the app to load it inside a Webview or launch it in an external browser.

### Files Affected
- `sero/android/app/src/main/AndroidManifest.xml`
- `sero/android/app/build.gradle.kts`
- `sero/pubspec.yaml`

---

## 2. Compile and Target SDK Configurations

### Current State
The app uses automated Flutter SDK hooks inside `build.gradle.kts`:
- `compileSdk = flutter.compileSdkVersion`
- `minSdk = flutter.minSdkVersion`
- `targetSdk = flutter.targetSdkVersion`

### What is Good
- Relying on the Flutter SDK defaults guarantees that updating the Flutter framework will automatically bump SDK parameters, ensuring the compilation toolchain stays up to date.

### What is Missing
- There is no hard definition of SDK targets, which means local developer environments with outdated Flutter installations might compile the app targeting old SDK versions (e.g. Android 13 instead of Android 14/15), leading to inconsistencies.

### What Can Break
- If compiled on an older Flutter SDK (pre-3.22), the target SDK will fall below Google Play's mandatory target SDK requirement (currently Target SDK 34/Android 14 is required). Play Console will reject AAB uploads that do not meet this target.

### Real-World Risk
- **High:** Automated rejection during APK/AAB upload to Google Play Console due to target SDK policy violations.

### Priority
- **P0** (Must verify compile SDK environment before submission)

### Recommended Fix
- Enforce a minimum Flutter version in the team's CI/CD pipeline or hardcode standard SDK values in the `local.properties` file if local developer SDKs vary, ensuring compilation always matches `compileSdk = 34` and `targetSdk = 34`.

### Files Affected
- `sero/android/app/build.gradle.kts`
- `sero/android/local.properties`

---

## 3. Package Name & Google Services Mapping

### Current State
The namespace and application ID are set to `sero.com` in `build.gradle.kts` and match the `google-services.json` client configuration.

### What is Good
- Mappings are consistent. Firebase features like Auth, Firestore, and FCM will authenticate requests correctly because the client bundle ID matches the Firebase project registry.

### What is Missing
- `sero.com` is a generic package name. Usually, Indian startups or production applications use a reverse domain name format related to their registered brand (e.g., `com.homes.app` or `in.society.sero`).

### What Can Break
- If the company launches under a different domain or brand name, changing the package name later requires modifying multiple files (directories, build systems, Firebase registries) and will release a *completely separate* app in the Play Store, causing old users to lose update access.

### Real-World Risk
- **Medium:** Operational drag and brand confusion if the package name needs a late-stage pivot.

### Priority
- **P1** (Must fix before pilot/beta users)

### Recommended Fix
- Perform a safe renaming of the package namespace from `sero.com` to the final registered production domain (e.g. `com.homes.society`) using search-and-replace across directories, and download a matching `google-services.json` from Firebase before compiling the release build.

### Files Affected
- `sero/android/app/build.gradle.kts`
- `sero/android/app/src/main/AndroidManifest.xml`
- `sero/android/app/google-services.json`
- Native activity folders in `sero/android/app/src/main/kotlin/`

---

## 4. Release Track & Review Credentials

### Current State
No dedicated Google Play reviewer test account flow is implemented. The app requires an active, approved society membership to log in.

### What is Good
- Strict registration logic prevents random internet users from logging into real housing societies.

### What is Missing
- Google Play reviewers require valid test credentials to bypass the phone number OTP and society approval stages. Because the signup flow sends registration requests to real society admins, a Play Store reviewer will get stuck on the "Pending Approval" screen, resulting in immediate app rejection.

### What Can Break
- Google Play Review team rejects the submission with a "We could not access your app features" notice.

### Real-World Risk
- **High:** Guaranteed release blocker during the Play Store submission review stage.

### Priority
- **P0** (Must fix before Play Store submission)

### Recommended Fix
- Implement a mock/sandbox bypass in the backend auth router (`/auth/login` and `/auth/register`) or client configuration. If a specific reviewer test number (e.g., `+919999999999` with password `PlayStoreTest123!`) is used:
  1. Auto-bypass the OTP screen.
  2. Map the account to a pre-approved, mock society (`society_id: "demo_society"`).
  3. Pre-populate this mock society with notices, mock visitors, and ledger entries so the reviewer can experience the entire app without requiring an admin's live action.

### Files Affected
- `society-backend/routes/auth.js`
- `sero/lib/services/auth_service.dart`
