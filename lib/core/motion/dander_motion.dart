import 'package:flutter/material.dart';

/// Utility class for checking the reduced-motion accessibility preference.
///
/// Use [isReduced] in any widget's [build] method to gate custom animations.
/// When `true`, widgets should skip or instantly complete their animations
/// to respect the user's accessibility settings.
///
/// Example:
/// ```dart
/// @override
/// Widget build(BuildContext context) {
///   if (DanderMotion.isReduced(context)) {
///     return widget.child; // skip animation
///   }
///   return MyAnimatedWidget(...);
/// }
/// ```
class DanderMotion {
  const DanderMotion._();

  /// Returns `true` when the user has enabled the "Reduce Motion" accessibility
  /// setting on their device, as reported via [MediaQuery.disableAnimations].
  static bool isReduced(BuildContext context) =>
      MediaQuery.of(context).disableAnimations;
}
