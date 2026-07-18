import 'package:flutter_test/flutter_test.dart';
import 'package:my_personal_tracker/core/logging/crash_reporter.dart';
import 'package:my_personal_tracker/core/logging/structured_logger.dart';

class MockCrashReporter implements CrashReporter {
  final List<String> logs = [];
  final List<dynamic> errors = [];

  @override
  void reportError(dynamic error, StackTrace? stackTrace, {dynamic reason}) {
    errors.add(error);
  }

  @override
  void reportLog(String message) {
    logs.add(message);
  }
}

void main() {
  group('LoggerService and CrashReporter Tests', () {
    late MockCrashReporter mockReporter;

    setUp(() {
      mockReporter = MockCrashReporter();
      LoggerService.addReporter(mockReporter);
    });

    tearDown(() {
      LoggerService.removeReporter(mockReporter);
    });

    test('Should forward non-error logs to reporter logs list', () {
      LoggerService.info('This is an info message');
      expect(mockReporter.logs.any((log) => log.contains('This is an info message')), isTrue);
      expect(mockReporter.errors.isEmpty, isTrue);
    });

    test('Should forward errors to reporter errors list', () {
      LoggerService.error('This is an error message', error: 'test-error');
      expect(mockReporter.errors.contains('test-error'), isTrue);
    });
  });
}
