import 'package:flutter_test/flutter_test.dart';
import 'package:sero/config/env.dart';
import 'package:sero/config/constants.dart';

void main() {
  group('Environment and Legal Config Verification Tests', () {
    test('AppConstants Legal URLs and Contact Support are fully defined', () {
      expect(AppConstants.privacyPolicyUrl, isNotEmpty);
      expect(AppConstants.termsConditionsUrl, isNotEmpty);
      expect(AppConstants.dataDeletionUrl, isNotEmpty);
      expect(AppConstants.supportEmail, isNotEmpty);

      // Verify that URLs look like correct HTTPS links and the email is valid
      expect(AppConstants.privacyPolicyUrl.startsWith('https://'), isTrue);
      expect(AppConstants.termsConditionsUrl.startsWith('https://'), isTrue);
      expect(AppConstants.dataDeletionUrl.startsWith('https://'), isTrue);
      expect(AppConstants.supportEmail.contains('@'), isTrue);
    });

    test('Environment default targeting parameters are in place', () {
      // By default, the app should boot in development environment
      expect(Environment.appEnv, equals('development'));
      expect(Environment.apiBaseUrl, isNotEmpty);

      // The validation method must pass cleanly under development configurations
      expect(() => Environment.validate(), returnsNormally);
    });
  });
}
