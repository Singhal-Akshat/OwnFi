import 'package:flutter_test/flutter_test.dart';
import 'package:my_personal_tracker/core/platform/platform_service.dart';

void main() {
  group('PlatformService Tests', () {
    test('DefaultPlatformService can be instantiated and returns expected values in test context', () {
      const platformService = DefaultPlatformService();
      // In flutter test execution environment, standard Dart VM environment rules apply.
      // Usually, it's recognized as the host OS (Linux/MacOS/Windows).
      expect(platformService.isWeb, isFalse);
      expect(platformService.isAndroid || platformService.isIOS || platformService.isLinux || platformService.isMacOS || platformService.isWindows, isTrue);
    });
  });
}
