import 'package:flutter/foundation.dart';
import 'crash_reporter.dart';

enum LogLevel { debug, info, warning, error, wtf }

class LoggerService {
  LoggerService._();

  static final List<CrashReporter> _reporters = [ConsoleCrashReporter()];

  static void addReporter(CrashReporter reporter) {
    _reporters.add(reporter);
  }

  static void removeReporter(CrashReporter reporter) {
    _reporters.remove(reporter);
  }

  static void log(LogLevel level, String message, {dynamic error, StackTrace? stackTrace}) {
    final timeStr = DateTime.now().toIso8601String();
    final prefix = '[${level.name.toUpperCase()}] [$timeStr]';
    final fullMessage = '$prefix $message';

    if (kDebugMode) {
      debugPrint(fullMessage);
      if (error != null) {
        debugPrint('$prefix Error: $error');
      }
      if (stackTrace != null) {
        debugPrint('$prefix StackTrace:\n$stackTrace');
      }
    }

    // Report warnings, errors, and wtf to crash reporters, or keep breadcrumbs
    for (final reporter in _reporters) {
      if (level == LogLevel.error || level == LogLevel.wtf) {
        reporter.reportError(error ?? message, stackTrace, reason: message);
      } else {
        reporter.reportLog(fullMessage);
      }
    }
  }

  static void debug(String message) => log(LogLevel.debug, message);
  static void info(String message) => log(LogLevel.info, message);
  static void warn(String message) => log(LogLevel.warning, message);
  static void error(String message, {dynamic error, StackTrace? stackTrace}) =>
      log(LogLevel.error, message, error: error, stackTrace: stackTrace);
  static void wtf(String message, {dynamic error, StackTrace? stackTrace}) =>
      log(LogLevel.wtf, message, error: error, stackTrace: stackTrace);
}
