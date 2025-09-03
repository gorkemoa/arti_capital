import 'package:flutter/foundation.dart';

class AppLogger {
  AppLogger._();

  static bool enabled = true;

  static void i(String message, {String tag = 'APP'}) {
    if (!enabled) return;
    debugPrint('[$tag] $message');
  }

  static void e(String message, {String tag = 'APP'}) {
    if (!enabled) return;
    debugPrint('[ERROR][$tag] $message');
  }
}



