# Building the Sero Release APK

Build the production APK once the backend URL is known. The API base URL is
build-time configurable via `--dart-define`; the entire app routes through
`Environment.apiBaseUrl` (see `lib/config/env.dart`).

## Command

```
cd sero
flutter clean
flutter pub get
flutter build apk --release --dart-define=API_BASE_URL=https://sero-api.onrender.com/api/v1
# output: build/app/outputs/flutter-apk/app-release.apk
```

Adjust `API_BASE_URL` if the backend is hosted elsewhere. If omitted, it
defaults to `http://10.0.2.2:3001/api/v1` (Android emulator → local dev),
which will NOT work on a real phone.

## Signing

Release builds are signed with the real keystore at
`android/sero-release.jks`, configured via `android/key.properties`
(git-ignored). Both must be present for a distributable build; otherwise the
build falls back to debug signing.

## Installing on teammates' phones

The team sideloads the APK directly (no Play Store):

1. Transfer `app-release.apk` to the phone.
2. In Android Settings, enable **Install unknown apps** for the app used to
   open it (e.g. Files, Chrome, or the messaging app).
3. Tap the APK and follow the prompt to install.

Each new APK should have a higher `version:` build number in `pubspec.yaml`
(the number after `+`) so it supersedes the previously installed one.
