import 'package:flutter/services.dart';

/// Centralised haptic feedback service.
///
/// All haptic calls are routed through this class so they can be silenced
/// in tests and the production behaviour stays consistent across the app.
abstract final class HapticService {
  /// Fired when the user starts a walk session.
  static Future<void> walkStarted() =>
      HapticFeedback.heavyImpact().catchError((_) {});

  /// Fired when the user ends a walk session.
  static Future<void> walkEnded() =>
      HapticFeedback.mediumImpact().catchError((_) {});

  /// Fired when the user answers a quiz question correctly.
  static Future<void> quizAnswerCorrect() =>
      HapticFeedback.lightImpact().catchError((_) {});

  /// Fired when the user answers a quiz question incorrectly.
  static Future<void> quizAnswerIncorrect() =>
      HapticFeedback.vibrate().catchError((_) {});

  /// Fired when a badge is unlocked.
  static Future<void> badgeEarned() =>
      HapticFeedback.heavyImpact().catchError((_) {});

  /// Fired when a new discovery is found.
  static Future<void> discoveryFound() =>
      HapticFeedback.selectionClick().catchError((_) {});
}
