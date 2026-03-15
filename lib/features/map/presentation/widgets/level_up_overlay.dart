import 'dart:async';

import 'package:flutter/material.dart';

import 'package:dander/core/haptics/haptic_service.dart';
import 'package:dander/core/subscription/milestone_type.dart';
import 'package:dander/core/theme/dander_colors.dart';
import 'package:dander/core/zone/level_up_detector.dart';
import 'package:dander/core/zone/zone_level.dart';
import 'package:dander/features/subscription/presentation/widgets/milestone_pro_suggestion_card.dart';
import 'package:dander/shared/widgets/confetti_overlay.dart';

/// Overlay widget that celebrates a zone level-up.
///
/// When [event] is non-null the banner is displayed with confetti and haptic
/// feedback. The overlay persists until the user taps it (tap-to-dismiss).
/// When [event] is null only [child] is shown.
///
/// When [showProSuggestion] is true and the user is not a Pro subscriber, a
/// [MilestoneProSuggestionCard] is shown beneath the banner after a 600 ms
/// delay. The card fades in over 300 ms using [AnimatedOpacity].
class LevelUpOverlay extends StatefulWidget {
  const LevelUpOverlay({
    super.key,
    required this.event,
    required this.child,
    this.onDismissed,
    this.showProSuggestion = false,
    this.milestoneType,
    this.onLearnAboutPro,
  });

  /// The level-up event to display, or `null` to show no overlay.
  final LevelUpEvent? event;

  /// The widget rendered beneath the overlay (typically the map).
  final Widget child;

  /// Called when the user taps to dismiss the overlay (via either "Continue"
  /// button or the background tap gesture).
  final VoidCallback? onDismissed;

  /// When `true` and [event] is non-null, shows a [MilestoneProSuggestionCard]
  /// below the level-up banner after a 600 ms delay. Has no effect when
  /// `false` or when [event] is `null`.
  final bool showProSuggestion;

  /// The type of milestone, used to select the contextual message inside the
  /// [MilestoneProSuggestionCard]. Required when [showProSuggestion] is `true`.
  final MilestoneType? milestoneType;

  /// Called when the user taps "Learn about Pro →" inside the Pro card.
  final VoidCallback? onLearnAboutPro;

  @override
  State<LevelUpOverlay> createState() => _LevelUpOverlayState();
}

class _LevelUpOverlayState extends State<LevelUpOverlay> {
  Timer? _proCardTimer;
  bool _showProCard = false;

  @override
  void didUpdateWidget(LevelUpOverlay old) {
    super.didUpdateWidget(old);

    // Trigger haptic on new level-up event.
    if (old.event == null && widget.event != null) {
      HapticService.levelUp();
    }

    // Start pro-card timer when a new event arrives (or when showProSuggestion
    // is toggled on while an event is already active).
    final eventJustArrived = old.event == null && widget.event != null;
    final suggestionEnabled =
        !old.showProSuggestion && widget.showProSuggestion;

    if ((eventJustArrived || suggestionEnabled) &&
        widget.showProSuggestion &&
        widget.event != null) {
      _scheduleProCard();
    }

    // Cancel the timer if the event was dismissed or suggestion turned off.
    if (widget.event == null || !widget.showProSuggestion) {
      _cancelProCard();
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.showProSuggestion && widget.event != null) {
      _scheduleProCard();
    }
  }

  void _scheduleProCard() {
    _proCardTimer?.cancel();
    _proCardTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() => _showProCard = true);
      }
    });
  }

  void _cancelProCard() {
    _proCardTimer?.cancel();
    _proCardTimer = null;
    if (_showProCard) {
      setState(() => _showProCard = false);
    }
  }

  @override
  void dispose() {
    _proCardTimer?.cancel();
    super.dispose();
  }

  void _dismiss() {
    widget.onDismissed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final hasEvent = widget.event != null;

    return Stack(
      children: [
        ConfettiOverlay(
          active: hasEvent,
          child: widget.child,
        ),
        if (hasEvent)
          Positioned.fill(
            // Background tap-to-dismiss layer (below the card content).
            child: GestureDetector(
              onTap: _dismiss,
              behavior: HitTestBehavior.opaque,
              child: const SizedBox.expand(),
            ),
          ),
        if (hasEvent)
          Positioned.fill(
            // Card content — sits above the gesture detector so buttons receive
            // pointer events directly.
            child: IgnorePointer(
              ignoring: false,
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    top: 16,
                    bottom: MediaQuery.of(context).padding.bottom + 80,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: _dismiss,
                        child: _LevelUpBanner(event: widget.event!),
                      ),
                      if (widget.showProSuggestion &&
                          widget.milestoneType != null)
                        AnimatedOpacity(
                          opacity: _showProCard ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 300),
                          child: _showProCard
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: MilestoneProSuggestionCard(
                                    milestoneType: widget.milestoneType!,
                                    onLearnAboutPro:
                                        widget.onLearnAboutPro ?? () {},
                                    onContinue: _dismiss,
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// The visual banner content rendered inside [LevelUpOverlay].
class _LevelUpBanner extends StatelessWidget {
  const _LevelUpBanner({required this.event});

  final LevelUpEvent event;

  String _formatRadius(double meters) {
    if (meters >= 1000) {
      final km = meters / 1000;
      final formatted =
          km == km.truncateToDouble() ? '${km.toInt()}km' : '${km}km';
      return formatted;
    }
    return '${meters.toInt()}m';
  }

  String _nextLevelText() {
    final nextLevel = event.newLevel + 1;
    final nextXp = ZoneLevel.xpForNextLevel(
      ZoneLevel.xpForLevel(event.newLevel),
    );
    if (nextXp == null) {
      return "You've reached the highest level!";
    }
    final currentLevelXp = ZoneLevel.xpForLevel(event.newLevel);
    final xpNeeded = nextXp - currentLevelXp;
    return 'Keep walking to reach Level $nextLevel ($xpNeeded XP)';
  }

  @override
  Widget build(BuildContext context) {
    final radiusText = _formatRadius(event.newRadiusMeters);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      decoration: BoxDecoration(
        color: DanderColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: DanderColors.secondary,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: DanderColors.secondary.withValues(alpha: 0.25),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Level ${event.newLevel}!',
            style: const TextStyle(
              color: DanderColors.secondary,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Explore up to $radiusText!',
            style: const TextStyle(
              color: DanderColors.onSurface,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _nextLevelText(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: DanderColors.onSurface.withValues(alpha: 0.7),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Tap to continue',
            style: TextStyle(
              color: DanderColors.onSurface.withValues(alpha: 0.4),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
