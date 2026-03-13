import 'dart:async';

import 'package:flutter/material.dart';
import 'package:dander/core/theme/app_theme.dart';
import 'package:dander/shared/widgets/dander_logo.dart';

/// Animated splash screen shown on app launch.
///
/// The logo fades and slides in over 1 500 ms, holds for 500 ms,
/// then calls [onComplete] so the host can navigate forward.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.onComplete});

  /// Called once the entrance animation and hold period have finished.
  final VoidCallback? onComplete;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const Duration _fadeDuration = Duration(milliseconds: 1500);
  static const Duration _holdDuration = Duration(milliseconds: 500);

  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  Timer? _holdTimer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: _fadeDuration,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward().whenComplete(_onAnimationDone);
  }

  void _onAnimationDone() {
    if (!mounted) return;
    _holdTimer = Timer(_holdDuration, () {
      if (mounted) widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DanderColors.surface,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DanderLogoMark(size: 96),
                const SizedBox(height: DanderSpacing.lg),
                Text(
                  'Dander',
                  style: DanderTextStyles.displayLarge.copyWith(
                    color: DanderColors.onSurface,
                    letterSpacing: 4,
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
