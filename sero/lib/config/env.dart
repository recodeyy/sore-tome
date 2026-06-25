class Environment {
  // Use 10.0.2.2 for Android Emulator, localhost for iOS/Web
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3001/api/v1',
  );

  static const String fallbackUrl = String.fromEnvironment(
    'FALLBACK_URL',
    defaultValue: 'http://localhost:3001/api/v1',
  );
}
