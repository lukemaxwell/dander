import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'package:dander/core/subscription/subscription_service.dart';
import 'package:dander/core/subscription/subscription_state.dart';
import 'package:dander/core/theme/dander_colors.dart';
import 'package:dander/core/theme/dander_spacing.dart';
import 'package:dander/core/theme/dander_text_styles.dart';
import 'package:dander/features/subscription/paywall_trigger.dart';
import 'package:dander/features/subscription/presentation/screens/paywall_screen.dart';

/// A pill-shaped badge displayed in the profile screen header.
///
/// Adapts its appearance based on the user's [SubscriptionState]:
///
/// - **Free**: transparent pill with gradient border, "Pro ›" text,
///   tapping navigates to [PaywallScreen].
/// - **Trial**: same pill, plus a subtitle "Pro trial · X days left" beneath.
/// - **Pro**: gradient-filled pill, sparkle icon + "Pro" text, tap is a no-op.
///
/// Reads [SubscriptionService] from [GetIt] and rebuilds reactively via
/// [ValueListenableBuilder].
///
/// The [onNavigate] callback is provided for testability — when supplied it
/// is called instead of pushing [PaywallScreen] directly.
class ProBadge extends StatelessWidget {
  const ProBadge({
    super.key,
    this.onNavigate,
  });

  /// Optional override for navigation (used in tests to avoid a full
  /// [Navigator] stack). When null the badge pushes [PaywallScreen] directly.
  final void Function(PaywallTrigger trigger)? onNavigate;

  @override
  Widget build(BuildContext context) {
    final service = GetIt.instance<SubscriptionService>();

    return ValueListenableBuilder<SubscriptionState>(
      valueListenable: service.state,
      builder: (context, state, _) {
        return switch (state) {
          SubscriptionStateFree() => _FreeBadge(onNavigate: onNavigate),
          SubscriptionStateTrial(:final daysLeft) => _TrialBadge(
              daysLeft: daysLeft,
              onNavigate: onNavigate,
            ),
          SubscriptionStatePro() => const _ProBadge(),
        };
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Free-user pill
// ---------------------------------------------------------------------------

class _FreeBadge extends StatelessWidget {
  const _FreeBadge({this.onNavigate});

  final void Function(PaywallTrigger trigger)? onNavigate;

  void _handleTap(BuildContext context) {
    if (onNavigate != null) {
      onNavigate!(PaywallTrigger.profile);
      return;
    }
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => const PaywallScreen(trigger: PaywallTrigger.profile),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Dander Pro. Tap to learn more.',
      child: GestureDetector(
        onTap: () => _handleTap(context),
        behavior: HitTestBehavior.opaque,
        // SizedBox ensures the touch target is always at least 44x44.
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: _GradientBorderPill(
              child: Text(
                'Pro ›',
                style: DanderTextStyles.labelMedium.copyWith(
                  color: DanderColors.onSurfaceMuted,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Trial pill (badge + subtitle)
// ---------------------------------------------------------------------------

class _TrialBadge extends StatelessWidget {
  const _TrialBadge({
    required this.daysLeft,
    this.onNavigate,
  });

  final int daysLeft;
  final void Function(PaywallTrigger trigger)? onNavigate;

  void _handleTap(BuildContext context) {
    if (onNavigate != null) {
      onNavigate!(PaywallTrigger.profile);
      return;
    }
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => const PaywallScreen(trigger: PaywallTrigger.profile),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Dander Pro trial. $daysLeft days left. Tap to manage.',
      child: GestureDetector(
        onTap: () => _handleTap(context),
        behavior: HitTestBehavior.opaque,
        // Minimum 44pt touch height achieved via padding around the content.
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: DanderSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _GradientBorderPill(
                child: Text(
                  'Pro ›',
                  style: DanderTextStyles.labelMedium.copyWith(
                    color: DanderColors.onSurfaceMuted,
                  ),
                ),
              ),
              const SizedBox(height: DanderSpacing.xs),
              Text(
                'Pro trial · $daysLeft days left',
                style: DanderTextStyles.labelSmall.copyWith(
                  color: DanderColors.secondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pro-subscriber pill
// ---------------------------------------------------------------------------

class _ProBadge extends StatelessWidget {
  const _ProBadge();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Dander Pro subscriber',
      child: SizedBox(
        height: 44,
        child: Center(
          child: _GradientBorderPill(
            fillGradient: _kProFill,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.auto_awesome,
                  size: 10,
                  color: DanderColors.secondary,
                ),
                const SizedBox(width: DanderSpacing.xs),
                Text(
                  'Pro',
                  style: DanderTextStyles.labelMedium.copyWith(
                    color: DanderColors.secondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared gradient-border pill
// ---------------------------------------------------------------------------

/// Renders a pill shape with a 1px gradient border (secondary → accent).
///
/// The gradient border is implemented by stacking two [Container]s:
/// - Outer: gradient [BoxDecoration] providing the border colour.
/// - Inner: slightly inset, with optional [fillGradient] or transparent fill.
///
/// This avoids any native gradient-border limitations in Flutter.
class _GradientBorderPill extends StatelessWidget {
  const _GradientBorderPill({
    required this.child,
    this.fillGradient,
  });

  final Widget child;

  /// Optional gradient fill for the inner container (e.g. Pro subscriber).
  /// When null the inner container is transparent.
  final Gradient? fillGradient;

  static const double _borderWidth = 1.0;
  static const double _height = 28.0;
  static const double _hPadding = 12.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [DanderColors.secondary, DanderColors.accent],
        ),
        borderRadius: BorderRadius.all(
          Radius.circular(DanderSpacing.borderRadiusFull),
        ),
      ),
      padding: const EdgeInsets.all(_borderWidth),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: _hPadding - _borderWidth,
        ),
        decoration: BoxDecoration(
          gradient: fillGradient,
          color: fillGradient == null ? Colors.transparent : null,
          borderRadius: const BorderRadius.all(
            Radius.circular(DanderSpacing.borderRadiusFull),
          ),
        ),
        child: Center(
          widthFactor: 1.0,
          child: child,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

/// Subtle gradient fill for the Pro subscriber state.
///
/// Colours are [DanderColors.secondary] and [DanderColors.accent] at ~15%
/// opacity (alpha 0x26 = 38 / 255 ≈ 15%). There are no named opacity-variant
/// tokens in [DanderColors] for these values, so they are derived inline and
/// documented here.
const LinearGradient _kProFill = LinearGradient(
  colors: [
    Color(0x26FF8F00), // DanderColors.secondary at 15% opacity
    Color(0x264FC3F7), // DanderColors.accent at 15% opacity
  ],
);
