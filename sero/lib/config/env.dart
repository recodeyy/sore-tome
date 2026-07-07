class Environment {
  // Production GCP Cloud Run backend is the DEFAULT so a plain
  // `flutter build apk` produces a working app (no emulator URL → no
  // "something went wrong" on real phones). For local development override at
  // build/run time, e.g.
  //   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3001/api/v1
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://sero-api-m477e5mida-el.a.run.app/api/v1',
  );

  static const String fallbackUrl = String.fromEnvironment(
    'FALLBACK_URL',
    defaultValue: 'https://sero-api-m477e5mida-el.a.run.app/api/v1',
  );
}
