import 'package:flutter/services.dart';

/// Centralised haptic feedback service.
///
/// All haptic calls are routed through this class so they can be silenced
/// in tests and the production behaviour stays consistent across the app.
///
/// Intensity map (mirrors the UX spec):
/// - Light  : [selectionClick] / [lightImpact]  — subtle confirmation
/// - Medium : [mediumImpact]                    — notable moment
/// - Heavy  : [heavyImpact]                     — celebratory moment
abstract final class HapticService {
  // ---------------------------------------------------------------------------
  // Light interactions
  // ---------------------------------------------------------------------------

  /// Fired when the user switches between bottom nav tabs.
  static Future<void> navTabSwitch() =>
      HapticFeedback.selectionClick().catchError((_) {});

  /// Fired when the user taps a discovery card.
  static Future<void> discoveryCardTap() =>
      HapticFeedback.lightImpact().catchError((_) {});

  /// Fired when the user answers a quiz question correctly.
  static Future<void> quizAnswerCorrect() =>
      HapticFeedback.lightImpact().catchError((_) {});

  /// Fired when the user answers a quiz question incorrectly.
  static Future<void> quizAnswerIncorrect() =>
      HapticFeedback.vibrate().catchError((_) {});

  // ---------------------------------------------------------------------------
  // Medium interactions
  // ---------------------------------------------------------------------------

  /// Fired when the user starts a walk session.
  static Future<void> walkStarted() =>
      HapticFeedback.mediumImpact().catchError((_) {});

  /// Fired when the user ends a walk session.
  static Future<void> walkEnded() =>
      HapticFeedback.mediumImpact().catchError((_) {});

  /// Fired when a new discovery (POI) is found during a walk.
  static Future<void> discoveryFound() =>
      HapticFeedback.mediumImpact().catchError((_) {});

  /// Fired when a badge is unlocked.
  static Future<void> badgeEarned() =>
      HapticFeedback.mediumImpact().catchError((_) {});

  // ---------------------------------------------------------------------------
  // Heavy / celebratory
  // ---------------------------------------------------------------------------

  /// Fired when the user's zone levels up.
  static Future<void> levelUp() =>
      HapticFeedback.heavyImpact().catchError((_) {});

  /// Fired when a rare discovery is found.
  static Future<void> rareDiscovery() =>
      HapticFeedback.heavyImpact().catchError((_) {});

  /// Fired when the user hits a quiz streak milestone.
  static Future<void> streakMilestone() =>
      HapticFeedback.heavyImpact().catchError((_) {});
}
