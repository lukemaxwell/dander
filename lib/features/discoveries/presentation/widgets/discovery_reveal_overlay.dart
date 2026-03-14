import 'package:flutter/material.dart';

import 'package:dander/core/discoveries/discovery.dart';
import 'package:dander/core/haptics/haptic_service.dart';
import 'package:dander/core/motion/dander_motion.dart';
import 'package:dander/core/theme/app_theme.dart';
import 'package:dander/core/theme/category_pin_config.dart';
import 'package:dander/core/theme/rarity_colors.dart';

/// Multi-step discovery reveal animation.
///
/// Shows a brief ceremonial reveal before the discovery card slides up.
/// The ceremony scales with rarity tier:
/// - [RarityTier.common]   — quick scale-in (500 ms)
/// - [RarityTier.uncommon] — scale + pulse ring (750 ms)
/// - [RarityTier.rare] / [RarityTier.legendary] — scale + pulse + glow (1000 ms)
///
/// When reduced motion is enabled, [onComplete] is called immediately with no
/// animation.
class DiscoveryRevealOverlay extends StatefulWidget {
  const DiscoveryRevealOverlay({
    super.key,
    required this.discovery,
    required this.onComplete,
  });

  final Discovery discovery;

  /// Called when the reveal sequence finishes (or immediately in reduced motion).
  final VoidCallback onComplete;

  /// Total animation duration for the given [rarity] tier.
  static Duration durationFor(RarityTier rarity) {
    switch (rarity) {
      case RarityTier.common:
        return const Duration(milliseconds: 500);
      case RarityTier.uncommon:
        return const Duration(milliseconds: 750);
      case RarityTier.rare:
      case RarityTier.legendary:
        return const Duration(milliseconds: 1000);
    }
  }

  @override
  State<DiscoveryRevealOverlay> createState() =>
      _DiscoveryRevealOverlayState();
}

class _DiscoveryRevealOverlayState extends State<DiscoveryRevealOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _controller;

  // Stage 1 — icon scales in (0 → 60% of total).
  late final Animation<double> _iconScale;

  // Stage 2 — name + rarity fade in (50 → 100% of total).
  late final Animation<double> _textOpacity;

  // Optional — pulse ring for uncommon+ (10 → 70% of total).
  late final Animation<double> _ringScale;
  late final Animation<double> _ringOpacity;

  @override
  void initState() {
    super.initState();

    final duration = DiscoveryRevealOverlay.durationFor(widget.discovery.rarity);
    _controller = AnimationController(vsync: this, duration: duration);

    _iconScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    _ringScale = Tween<double>(begin: 0.8, end: 2.2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.7, curve: Curves.easeOut),
      ),
    );

    _ringOpacity = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.7, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (DanderMotion.isReduced(context)) {
      // Reduced motion — skip reveal and notify caller on next frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onComplete();
      });
      return;
    }
    // Fire rarity-appropriate haptic at the start of the reveal.
    HapticService.discoveryByRarity(widget.discovery.rarity);
    _controller.forward().then((_) {
      if (mounted) widget.onComplete();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _showPulseRing =>
      widget.discovery.rarity == RarityTier.uncommon ||
      widget.discovery.rarity == RarityTier.rare ||
      widget.discovery.rarity == RarityTier.legendary;

  bool get _showGlow =>
      widget.discovery.rarity == RarityTier.rare ||
      widget.discovery.rarity == RarityTier.legendary;

  @override
  Widget build(BuildContext context) {
    if (DanderMotion.isReduced(context)) {
      return const SizedBox.shrink();
    }

    final config = CategoryPinConfig.forCategory(widget.discovery.category);
    final rarityColor = RarityColors.forTier(widget.discovery.rarity);
    final iconColor = _showGlow ? rarityColor : config.color;

    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.55),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon with optional pulse ring + glow.
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Pulse ring (uncommon+).
                        if (_showPulseRing)
                          Transform.scale(
                            scale: _ringScale.value,
                            child: Opacity(
                              opacity: _ringOpacity.value.clamp(0.0, 1.0),
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: iconColor,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),

                        // Icon container.
                        Transform.scale(
                          scale: _iconScale.value.clamp(0.0, 1.2),
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: iconColor.withValues(alpha: 0.15),
                              boxShadow: _showGlow
                                  ? [
                                      BoxShadow(
                                        color:
                                            iconColor.withValues(alpha: 0.4),
                                        blurRadius: 24,
                                        spreadRadius: 4,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Icon(config.icon, color: iconColor, size: 40),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Name + rarity fade in.
                  Opacity(
                    opacity: _textOpacity.value.clamp(0.0, 1.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.discovery.name,
                          style: DanderTextStyles.titleMedium.copyWith(
                            color: DanderColors.onSurface,
                            fontSize: 20,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: rarityColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            RarityColors.label(widget.discovery.rarity),
                            style: DanderTextStyles.labelMedium.copyWith(
                              color: rarityColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
