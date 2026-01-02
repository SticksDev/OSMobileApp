import 'package:flutter/foundation.dart';

class Logger {
  static void log(String message, {String? tag}) {
    if (kDebugMode) {
      final timestamp = DateTime.now().toString();
      final prefix = tag != null ? '[$tag]' : '[APP]';
      print('$timestamp $prefix $message');
    }
  }

  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (kDebugMode) {
      final timestamp = DateTime.now().toString();
      final prefix = tag != null ? '[$tag]' : '[APP]';
      print('$timestamp $prefix ERROR: $message');
      if (error != null) {
        print('$timestamp $prefix Error details: $error');
      }
      if (stackTrace != null) {
        print('$timestamp $prefix Stack trace:\n$stackTrace');
      }
    }
  }

  static void debug(String message, {String? tag}) {
    if (kDebugMode) {
      final timestamp = DateTime.now().toString();
      final prefix = tag != null ? '[$tag]' : '[APP]';
      print('$timestamp $prefix DEBUG: $message');
    }
  }
}
