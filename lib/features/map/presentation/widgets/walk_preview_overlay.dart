import 'package:flutter/material.dart';

import 'package:dander/core/motion/dander_motion.dart';
import 'package:dander/core/theme/app_theme.dart';

/// A full-screen overlay that plays a brief animated preview of what
/// exploration looks like — simulating fog clearing, a POI discovery,
/// and XP appearing.
///
/// Shows only on first launch. The animation plays automatically, then
/// a "Tap to continue" prompt appears. The user must tap to dismiss.
/// On reduced motion, shows a static card with the tagline instead.
///
/// Calls [onComplete] when the user taps to dismiss.
class WalkPreviewOverlay extends StatefulWidget {
  const WalkPreviewOverlay({
    super.key,
    required this.isFirstLaunch,
    required this.onComplete,
  });

  /// Whether this is the first launch. If false, [onComplete] fires
  /// immediately and nothing renders.
  final bool isFirstLaunch;

  /// Called when the user taps to dismiss the overlay.
  final VoidCallback onComplete;

  @override
  State<WalkPreviewOverlay> createState() => _WalkPreviewOverlayState();
}

class _WalkPreviewOverlayState extends State<WalkPreviewOverlay>
    with TickerProviderStateMixin {
  static const _animationDuration = Duration(seconds: 5);
  static const _fadeOutDuration = Duration(milliseconds: 800);

  AnimationController? _mainController;
  AnimationController? _fadeOutController;
  late final Animation<double> _fadeOut;
  bool _dismissed = false;
  bool _animationComplete = false;

  @override
  void initState() {
    super.initState();

    if (!widget.isFirstLaunch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onComplete();
      });
      return;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!widget.isFirstLaunch || _mainController != null) return;

    final reducedMotion = DanderMotion.isReduced(context);

    _fadeOutController = AnimationController(
      vsync: this,
      duration: _fadeOutDuration,
    );
    _fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeOutController!, curve: Curves.easeOut),
    );

    if (reducedMotion) {
      // No animation — show static card, ready to dismiss immediately.
      _mainController = AnimationController(
        vsync: this,
        duration: Duration.zero,
      );
      setState(() => _animationComplete = true);
    } else {
      _mainController = AnimationController(
        vsync: this,
        duration: _animationDuration,
      )..forward().then((_) {
          if (mounted) {
            setState(() => _animationComplete = true);
          }
        });
    }
  }

  void _dismiss() {
    if (_dismissed || !mounted) return;
    _dismissed = true;
    _fadeOutController?.forward().then((_) {
      if (mounted) {
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _mainController?.dispose();
    _fadeOutController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isFirstLaunch) return const SizedBox.shrink();

    final controller = _fadeOutController;
    if (controller == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: _dismiss,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) => Opacity(
          opacity: _fadeOut.value,
          child: child,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: DanderColors.surface.withValues(alpha: 0.85),
          ),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: DanderSpacing.pagePadding,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Simulated map preview area
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: DanderColors.accent.withValues(alpha: 0.3),
                          width: 1,
                        ),
                        color: DanderColors.primary.withValues(alpha: 0.5),
                      ),
                      child: _mainController != null
                          ? AnimatedBuilder(
                              animation: _mainController!,
                              builder: (context, _) => CustomPaint(
                                painter: _PreviewPainter(
                                  progress: _mainController!.value,
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    const SizedBox(height: DanderSpacing.xl),
                    Text(
                      'Every walk reveals more of your world',
                      style: DanderTextStyles.titleMedium.copyWith(
                        color: DanderColors.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: DanderSpacing.sm),
                    Text(
                      'Walk to clear the fog and discover hidden places',
                      style: DanderTextStyles.bodyMediumMuted,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: DanderSpacing.xxl),
                    AnimatedOpacity(
                      opacity: _animationComplete ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 400),
                      child: Text(
                        'Tap to continue',
                        key: const Key('tap_to_continue'),
                        style: DanderTextStyles.labelMedium.copyWith(
                          color: DanderColors.accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints a simple simulated fog-clearing animation inside the preview circle.
class _PreviewPainter extends CustomPainter {
  _PreviewPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2 - 10;

    // Expanding clear circle (fog clearing)
    final clearRadius = maxRadius * progress.clamp(0.0, 0.8) / 0.8;
    final clearPaint = Paint()
      ..color = DanderColors.accent.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, clearRadius, clearPaint);

    // Bright edge ring
    final ringPaint = Paint()
      ..color = DanderColors.accent.withValues(alpha: 0.4 * progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, clearRadius, ringPaint);

    // POI dot appears at 60% progress
    if (progress > 0.6) {
      final poiOpacity = ((progress - 0.6) / 0.2).clamp(0.0, 1.0);
      final poiOffset = Offset(center.dx + 30, center.dy - 20);
      final poiPaint = Paint()
        ..color = DanderColors.rarityRare.withValues(alpha: poiOpacity);
      canvas.drawCircle(poiOffset, 6, poiPaint);

      // Ring around POI
      final poiRingPaint = Paint()
        ..color = DanderColors.rarityRare.withValues(alpha: poiOpacity * 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(poiOffset, 10, poiRingPaint);
    }
  }

  @override
  bool shouldRepaint(_PreviewPainter oldDelegate) =>
      progress != oldDelegate.progress;
}
