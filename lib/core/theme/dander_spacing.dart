import 'package:flutter/material.dart';

/// Spacing scale and border-radius constants for the Dander design system.
///
/// Base unit is 4 px.  All spacing values are multiples of this base.
abstract final class DanderSpacing {
  // ---------------------------------------------------------------------------
  // Spacing scale (4 px base)
  // ---------------------------------------------------------------------------

  /// 4 px — extra small.
  static const double xs = 4.0;

  /// 8 px — small.
  static const double sm = 8.0;

  /// 12 px — medium.
  static const double md = 12.0;

  /// 16 px — large (default page padding).
  static const double lg = 16.0;

  /// 24 px — extra large.
  static const double xl = 24.0;

  /// 32 px — double extra large.
  static const double xxl = 32.0;

  /// 48 px — triple extra large.
  static const double xxxl = 48.0;

  // ---------------------------------------------------------------------------
  // Border radii
  // ---------------------------------------------------------------------------

  /// 8 px radius — small (chips, tags).
  static const double borderRadiusSm = 8.0;

  /// 12 px radius — medium (buttons).
  static const double borderRadiusMd = 12.0;

  /// 16 px radius — large (cards).
  static const double borderRadiusLg = 16.0;

  /// 24 px radius — extra large (bottom sheets, dialogs).
  static const double borderRadiusXl = 24.0;

  /// 100 px radius — pill / fully rounded.
  static const double borderRadiusFull = 100.0;

  // ---------------------------------------------------------------------------
  // Common EdgeInsets presets
  // ---------------------------------------------------------------------------

  /// Standard screen page padding (16 all sides).
  static const EdgeInsets pagePadding = EdgeInsets.all(lg);

  /// Card internal padding (16 all sides).
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);

  /// Horizontal list padding (16 h, 8 v).
  static const EdgeInsets listPadding = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: sm,
  );

  /// Chip / filter pill padding.
  static const EdgeInsets chipPadding = EdgeInsets.symmetric(
    horizontal: md,
    vertical: xs,
  );
}
