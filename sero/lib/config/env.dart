class Environment {
  static const String appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  // Use 10.0.2.2 for Android Emulator, localhost for iOS/Web
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3001/api/v1',
  );

  static const String fallbackUrl = String.fromEnvironment(
    'FALLBACK_URL',
    defaultValue: 'http://localhost:3001/api/v1',
  );

  /// Assert that production configurations point only to a live public server.
  static void validate() {
    if (appEnv == 'production' || appEnv == 'prod') {
      if (apiBaseUrl.contains('localhost') || 
          apiBaseUrl.contains('127.0.0.1') || 
          apiBaseUrl.contains('10.0.2.2')) {
        throw UnsupportedError(
          'CRITICAL CONFIGURATION ERROR:\n'
          'The application target is set to Production (--dart-define=APP_ENV=production), '
          'but the API server URL is targeting a local loopback server ($apiBaseUrl).\n'
          'Please specify a valid public server domain via --dart-define=API_BASE_URL=https://api.domain.com/api/v1'
        );
      }
    }
  }
}
