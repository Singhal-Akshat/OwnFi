import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

class GemmaInitializer {
  static bool _initialized = false;

  static Future<void> ensureInitialized() async {
    if (_initialized) return;
    try {
      await FlutterGemma.initialize();
      _initialized = true;
      debugPrint('FlutterGemma initialized successfully (lazy-loaded).');
    } catch (e) {
      debugPrint('Failed to initialize FlutterGemma lazy-load: $e');
      rethrow;
    }
  }
}
