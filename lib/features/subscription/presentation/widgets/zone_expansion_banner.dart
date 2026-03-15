import 'dart:async';

import 'package:flutter/material.dart';

import 'package:dander/core/motion/dander_motion.dart';
import 'package:dander/core/theme/app_theme.dart';

/// A dismissable top-of-map banner prompting free users to unlock unlimited
/// zones when they are detected outside their existing zone boundaries.
///
/// Behaviour:
/// - Slides in from the top with a [SlideTransition] + [FadeTransition]
///   (250ms, [Curves.easeOut]).
/// - Respects reduced-motion: if [DanderMotion.isReduced] is true, the
///   transition is skipped and the banner is shown/hidden immediately.
/// - Auto-dismisses after [autoDismissDelay] with a 200ms fade-out.
/// - Swipe up ([DismissDirection.up]) or tap the X button dismisses
///   immediately and calls [onDismiss].
/// - Tapping anywhere else on the banner calls [onNavigateToPaywall].
class ZoneExpansionBanner extends StatefulWidget {
  const ZoneExpansionBanner({
    super.key,
    required this.onNavigateToPaywall,
    this.onDismiss,
    @visibleForTesting
    this.autoDismissDelay = const Duration(seconds: 8),
  });

  /// Called when the user taps the banner body (excluding the X button).
  final VoidCallback onNavigateToPaywall;

  /// Called when the banner is dismissed (X tap, swipe up, or auto-dismiss).
  final VoidCallback? onDismiss;

  /// How long before the banner auto-dismisses itself.
  ///
  /// Defaults to 8 seconds. Override in tests via `@visibleForTesting`.
  final Duration autoDismissDelay;

  @override
  State<ZoneExpansionBanner> createState() => _ZoneExpansionBannerState();
}

class _ZoneExpansionBannerState extends State<ZoneExpansionBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  Timer? _autoDismissTimer;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only start the entrance animation once — guard with _dismissed.
    if (!_dismissed && !_controller.isAnimating && _controller.value == 0.0) {
      _startEntrance();
    }
  }

  void _startEntrance() {
    final reduced = DanderMotion.isReduced(context);
    if (reduced) {
      _controller.value = 1.0;
    } else {
      _controller.forward();
    }

    // Schedule auto-dismiss after the delay.
    _autoDismissTimer = Timer(widget.autoDismissDelay, _autoDismiss);
  }

  Future<void> _autoDismiss() async {
    if (!mounted || _dismissed) return;
    final reduced = DanderMotion.isReduced(context);
    if (!reduced) {
      // Fade out over 200ms before calling onDismiss.
      await _controller.animateTo(
        0.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeIn,
      );
    }
    _callDismiss();
  }

  void _dismiss() {
    if (_dismissed) return;
    _autoDismissTimer?.cancel();
    _callDismiss();
  }

  void _callDismiss() {
    if (_dismissed) return;
    _dismissed = true;
    widget.onDismiss?.call();
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = DanderMotion.isReduced(context);

    Widget banner = _BannerContent(
      onNavigateToPaywall: widget.onNavigateToPaywall,
      onDismiss: _dismiss,
    );

    if (!reduced) {
      banner = FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: banner,
        ),
      );
    }

    return Dismissible(
      key: const ValueKey('zone_expansion_banner'),
      direction: DismissDirection.up,
      onDismissed: (_) => _dismiss(),
      child: banner,
    );
  }
}

// ---------------------------------------------------------------------------
// Banner content (layout)
// ---------------------------------------------------------------------------

class _BannerContent extends StatelessWidget {
  const _BannerContent({
    required this.onNavigateToPaywall,
    required this.onDismiss,
  });

  final VoidCallback onNavigateToPaywall;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DanderSpacing.lg),
      child: GestureDetector(
        onTap: onNavigateToPaywall,
        behavior: HitTestBehavior.opaque,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(
            horizontal: DanderSpacing.lg,
            vertical: DanderSpacing.md,
          ),
          decoration: BoxDecoration(
            color: DanderColors.surfaceElevated,
            borderRadius:
                BorderRadius.circular(DanderSpacing.borderRadiusLg),
            border: Border.all(
              color: DanderColors.cardBorder,
              width: 0.5,
            ),
            boxShadow: DanderElevation.level2,
          ),
          child: Row(
            children: [
              const Icon(
                Icons.location_pin,
                size: 20,
                color: DanderColors.accent,
              ),
              const SizedBox(width: DanderSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "You're in a new area",
                      style: DanderTextStyles.bodyMedium,
                    ),
                    Text(
                      'Unlock unlimited zones →',
                      style: DanderTextStyles.labelLarge.copyWith(
                        color: DanderColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              // 44×44 touch target for the X button.
              SizedBox(
                width: 44,
                height: 44,
                child: GestureDetector(
                  onTap: onDismiss,
                  behavior: HitTestBehavior.opaque,
                  child: const Center(
                    child: Icon(
                      Icons.close,
                      size: 18,
                      color: DanderColors.onSurfaceMuted,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
