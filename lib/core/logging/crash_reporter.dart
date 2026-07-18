abstract class CrashReporter {
  void reportError(dynamic error, StackTrace? stackTrace, {dynamic reason});
  void reportLog(String message);
}

class ConsoleCrashReporter implements CrashReporter {
  @override
  void reportError(dynamic error, StackTrace? stackTrace, {dynamic reason}) {
    // In production, this would send to Sentry, Firebase Crashlytics, etc.
    print('[ConsoleCrashReporter] REPORT ERROR: $error');
    if (reason != null) {
      print('[ConsoleCrashReporter] REASON: $reason');
    }
    if (stackTrace != null) {
      print('[ConsoleCrashReporter] STACK TRACE:\n$stackTrace');
    }
  }

  @override
  void reportLog(String message) {
    print('[ConsoleCrashReporter] BREADCRUMB: $message');
  }
}
