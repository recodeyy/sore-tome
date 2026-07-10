class Environment {
  // Production backend is the SERO API on Render (Neon Postgres + Upstash Redis),
  // the DEFAULT so a plain `flutter build apk` produces a working app on real
  // phones. GCP Cloud Run has been retired (it was expiring). For local
  // development override at build/run time, e.g.
  //   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3001/api/v1
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://sero-api-live.onrender.com/api/v1',
  );

  static const String fallbackUrl = String.fromEnvironment(
    'FALLBACK_URL',
    defaultValue: 'https://sero-api-live.onrender.com/api/v1',
  );
}
