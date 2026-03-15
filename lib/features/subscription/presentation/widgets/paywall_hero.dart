import 'package:flutter/material.dart';

import 'package:dander/core/motion/dander_motion.dart';
import 'package:dander/core/theme/dander_colors.dart';
import 'package:dander/features/subscription/paywall_trigger.dart';

/// 200px contextual hero area at the top of the paywall screen.
///
/// Each [PaywallTrigger] variant renders a distinct animated preview:
/// - [PaywallTrigger.profile]       — fog circle pulsing (scale 0.9↔1.1, 2s)
/// - [PaywallTrigger.quizLimit]     — score ring filling (0→1, 2s)
/// - [PaywallTrigger.zoneExpansion] — three zone circles pulsing in sequence
/// - [PaywallTrigger.stats]         — chart lines drawing (opacity 0→1, 2s)
/// - [PaywallTrigger.milestone]     — amber glow pulse (1s)
///
/// When [DanderMotion.isReduced] is true, a static gradient container is
/// shown instead of any animation.
class PaywallHero extends StatefulWidget {
  const PaywallHero({
    super.key,
    required this.trigger,
  });

  final PaywallTrigger trigger;

  @override
  State<PaywallHero> createState() => _PaywallHeroState();
}

class _PaywallHeroState extends State<PaywallHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Create controller but do NOT start it yet — reduced motion check
    // requires a BuildContext which is only available in didChangeDependencies.
    _controller = AnimationController(
      vsync: this,
      duration: _durationFor(widget.trigger),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Start (or stop) animation based on current motion preference.
    // Called on first mount and whenever MediaQuery changes (e.g. user
    // toggles reduce-motion in accessibility settings mid-session).
    if (DanderMotion.isReduced(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: _reverseFor(widget.trigger));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Duration _durationFor(PaywallTrigger trigger) => switch (trigger) {
        PaywallTrigger.profile => const Duration(seconds: 2),
        PaywallTrigger.quizLimit => const Duration(seconds: 2),
        PaywallTrigger.zoneExpansion => const Duration(milliseconds: 2500),
        PaywallTrigger.stats => const Duration(seconds: 2),
        PaywallTrigger.milestone => const Duration(seconds: 1),
      };

  bool _reverseFor(PaywallTrigger trigger) => switch (trigger) {
        PaywallTrigger.profile => true,
        PaywallTrigger.quizLimit => false,
        PaywallTrigger.zoneExpansion => false,
        PaywallTrigger.stats => false,
        PaywallTrigger.milestone => true,
      };

  @override
  Widget build(BuildContext context) {
    const heroHeight = 200.0;

    if (DanderMotion.isReduced(context)) {
      return _StaticHero(trigger: widget.trigger, height: heroHeight);
    }

    return SizedBox(
      height: heroHeight,
      width: double.infinity,
      child: _AnimatedHero(
        trigger: widget.trigger,
        controller: _controller,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Static fallback (reduced motion)
// ---------------------------------------------------------------------------

class _StaticHero extends StatelessWidget {
  const _StaticHero({required this.trigger, required this.height});

  final PaywallTrigger trigger;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            DanderColors.secondary.withValues(alpha: 0.15),
            DanderColors.accent.withValues(alpha: 0.08),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Animated hero dispatcher
// ---------------------------------------------------------------------------

class _AnimatedHero extends StatelessWidget {
  const _AnimatedHero({
    required this.trigger,
    required this.controller,
  });

  final PaywallTrigger trigger;
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return switch (trigger) {
      PaywallTrigger.profile => _ProfileHero(controller: controller),
      PaywallTrigger.quizLimit => _QuizHero(controller: controller),
      PaywallTrigger.zoneExpansion => _ZoneHero(controller: controller),
      PaywallTrigger.stats => _StatsHero(controller: controller),
      PaywallTrigger.milestone => _MilestoneHero(controller: controller),
    };
  }
}

// ---------------------------------------------------------------------------
// Profile hero — pulsing fog circle
// ---------------------------------------------------------------------------

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    final scale = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
    );
    return SizedBox(
      height: 200,
      width: double.infinity,
      child: Center(
        child: AnimatedBuilder(
          animation: scale,
          builder: (_, __) => Transform.scale(
            scale: scale.value,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: DanderColors.accent.withValues(alpha: 0.15),
                border: Border.all(
                  color: DanderColors.accent.withValues(alpha: 0.4),
                  width: 1.5,
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
// Quiz hero — score ring filling
// ---------------------------------------------------------------------------

class _QuizHero extends StatelessWidget {
  const _QuizHero({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    final fill = CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutCubic,
    );
    return SizedBox(
      height: 200,
      width: double.infinity,
      child: Center(
        child: AnimatedBuilder(
          animation: fill,
          builder: (_, __) => SizedBox(
            width: 90,
            height: 90,
            child: CircularProgressIndicator(
              value: fill.value,
              strokeWidth: 6,
              backgroundColor: DanderColors.accent.withValues(alpha: 0.15),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(DanderColors.accent),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Zone expansion hero — three circles pulsing in staggered sequence
// ---------------------------------------------------------------------------

class _ZoneHero extends StatelessWidget {
  const _ZoneHero({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    final offsets = [0.0, 0.3, 0.6];
    return SizedBox(
      height: 200,
      width: double.infinity,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: offsets.map((offset) {
            final anim = Tween<double>(begin: 0.6, end: 1.0).animate(
              CurvedAnimation(
                parent: controller,
                curve: Interval(
                  offset,
                  (offset + 0.4).clamp(0.0, 1.0),
                  curve: Curves.easeOutCubic,
                ),
              ),
            );
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: AnimatedBuilder(
                animation: anim,
                builder: (_, __) => Opacity(
                  opacity: anim.value,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: DanderColors.secondary.withValues(alpha: 0.15),
                      border: Border.all(
                        color:
                            DanderColors.secondary.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stats hero — chart lines fading in
// ---------------------------------------------------------------------------

class _StatsHero extends StatelessWidget {
  const _StatsHero({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    final opacity = CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutCubic,
    );
    return SizedBox(
      height: 200,
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: AnimatedBuilder(
          animation: opacity,
          builder: (_, __) => Opacity(
            opacity: opacity.value.clamp(0.2, 1.0),
            child: CustomPaint(
              painter: _ChartLinesPainter(),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChartLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = DanderColors.accent.withValues(alpha: 0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Simple suggestive bar chart lines
    final barCount = 6;
    final barWidth = size.width / (barCount * 2);
    final heights = [0.4, 0.7, 0.5, 0.9, 0.6, 0.8];

    for (var i = 0; i < barCount; i++) {
      final x = i * barWidth * 2 + barWidth / 2;
      final barHeight = size.height * heights[i];
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x, size.height - barHeight),
        paint..strokeWidth = barWidth * 0.7,
      );
    }
  }

  @override
  bool shouldRepaint(_ChartLinesPainter old) => false;
}

// ---------------------------------------------------------------------------
// Milestone hero — amber glow pulse
// ---------------------------------------------------------------------------

class _MilestoneHero extends StatelessWidget {
  const _MilestoneHero({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    final glow = Tween<double>(begin: 0.2, end: 0.8).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
    );
    return SizedBox(
      height: 200,
      width: double.infinity,
      child: Center(
        child: AnimatedBuilder(
          animation: glow,
          builder: (_, __) => Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: DanderColors.secondary.withValues(alpha: 0.1),
              boxShadow: [
                BoxShadow(
                  color: DanderColors.secondary.withValues(alpha: glow.value),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(
              Icons.star,
              color: DanderColors.secondary,
              size: 36,
            ),
          ),
        ),
      ),
    );
  }
}
