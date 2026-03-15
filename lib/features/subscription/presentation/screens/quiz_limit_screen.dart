import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'package:dander/core/analytics/analytics_event.dart';
import 'package:dander/core/analytics/analytics_service.dart';
import 'package:dander/core/motion/dander_motion.dart';
import 'package:dander/core/theme/dander_colors.dart';
import 'package:dander/core/theme/dander_spacing.dart';
import 'package:dander/core/theme/dander_text_styles.dart';
import 'package:dander/features/subscription/paywall_trigger.dart';
import 'package:dander/features/subscription/presentation/screens/paywall_screen.dart';

/// The quiz completion / daily-limit screen.
///
/// Shown after a free user answers their 10th quiz question.  It celebrates
/// their session first, then offers a Pro extension option.
///
/// Parameters:
/// - [correct] — number of correct answers in the session.
/// - [total] — total questions answered (always 10 for the daily limit).
///
/// "Done for today" pops the current route with no confirmation.
/// "Try Pro free for 7 days" pushes [PaywallScreen] with
/// [PaywallTrigger.quizLimit].
class QuizLimitScreen extends StatefulWidget {
  const QuizLimitScreen({
    super.key,
    required this.correct,
    required this.total,
  });

  /// Number of correct answers in the session.
  final int correct;

  /// Total questions in the session (used for the score label and dots).
  final int total;

  @override
  State<QuizLimitScreen> createState() => _QuizLimitScreenState();
}

class _QuizLimitScreenState extends State<QuizLimitScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Dot stagger: each dot fades in 30ms apart.
  late final List<Animation<double>> _dotAnimations;

  // Pro suggestion fades in 400ms after the last dot completes.
  late final Animation<double> _proSuggestionOpacity;

  static const _dotCount = 10;
  static const _dotStaggerMs = 30;
  // Last dot ends at: _dotCount * _dotStaggerMs + dot fade duration (200ms)
  static const _dotsEndMs = _dotCount * _dotStaggerMs + 200;
  // Pro suggestion starts 400ms after dots complete.
  static const _proStartMs = _dotsEndMs + 400;
  static const _proFadeDurationMs = 300;
  static const _totalDurationMs = _proStartMs + _proFadeDurationMs;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _totalDurationMs),
    );

    // Build per-dot opacity animations with 30ms stagger.
    _dotAnimations = List.generate(_dotCount, (i) {
      final startMs = i * _dotStaggerMs;
      final endMs = startMs + 200;
      final start = startMs / _totalDurationMs;
      final end = (endMs / _totalDurationMs).clamp(0.0, 1.0);
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });

    // Pro suggestion animation.
    final proStart = _proStartMs / _totalDurationMs;
    final proEnd =
        ((_proStartMs + _proFadeDurationMs) / _totalDurationMs).clamp(0.0, 1.0);
    _proSuggestionOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(proStart, proEnd, curve: Curves.easeOut),
      ),
    );

    // Fire analytics event.
    GetIt.instance<AnalyticsService>().track(
      QuizLimitReached(correct: widget.correct, total: widget.total),
    );

    // Start animations after first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDone() => Navigator.of(context).pop();

  void _onTryPro() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            const PaywallScreen(trigger: PaywallTrigger.quizLimit),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reduced = DanderMotion.isReduced(context);

    return Scaffold(
      backgroundColor: DanderColors.surface,
      body: SafeArea(
        child: Padding(
          padding: DanderSpacing.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: DanderSpacing.xxl),

              // Accent glow icon.
              const Icon(
                Icons.auto_awesome,
                size: 48,
                color: DanderColors.secondary,
              ),
              const SizedBox(height: DanderSpacing.lg),

              // Headline.
              Text(
                'Nice work today',
                style: DanderTextStyles.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: DanderSpacing.sm),

              // Score text.
              Text(
                '${widget.correct} out of ${widget.total} correct',
                style: DanderTextStyles.bodyLargeMuted,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: DanderSpacing.xl),

              // Score dots row.
              _ScoreDotsRow(
                key: const ValueKey('score_dot_row'),
                correct: widget.correct,
                total: widget.total,
                dotAnimations: reduced
                    ? List.generate(
                        _dotCount,
                        (_) => const AlwaysStoppedAnimation(1.0),
                      )
                    : _dotAnimations,
              ),
              const SizedBox(height: DanderSpacing.xl),

              // Pro suggestion — fades in 400ms after dots complete.
              AnimatedBuilder(
                animation: _proSuggestionOpacity,
                builder: (_, child) => Opacity(
                  opacity: reduced ? 1.0 : _proSuggestionOpacity.value,
                  child: child,
                ),
                child: _ProSuggestionSection(
                  onDone: _onDone,
                  onTryPro: _onTryPro,
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
// Score dots row
// ---------------------------------------------------------------------------

class _ScoreDotsRow extends StatelessWidget {
  const _ScoreDotsRow({
    super.key,
    required this.correct,
    required this.total,
    required this.dotAnimations,
  });

  final int correct;
  final int total;
  final List<Animation<double>> dotAnimations;

  static const _dotSize = 12.0;
  static const _dotSpacing = 8.0;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(dotAnimations.length, (i) {
        final Color color;
        if (i < correct) {
          color = DanderColors.accent;
        } else if (i < total) {
          color = DanderColors.error;
        } else {
          color = DanderColors.onSurfaceDisabled;
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: _dotSpacing / 2),
          child: AnimatedBuilder(
            animation: dotAnimations[i],
            builder: (_, __) => Opacity(
              opacity: dotAnimations[i].value,
              child: Container(
                width: _dotSize,
                height: _dotSize,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// Pro suggestion section
// ---------------------------------------------------------------------------

class _ProSuggestionSection extends StatelessWidget {
  const _ProSuggestionSection({
    required this.onDone,
    required this.onTryPro,
  });

  final VoidCallback onDone;
  final VoidCallback onTryPro;

  static const _buttonHeight = 52.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Want to keep practising?',
          style: DanderTextStyles.bodyMediumMuted,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: DanderSpacing.lg),

        // "Try Pro free for 7 days" — filled, secondary color.
        SizedBox(
          height: _buttonHeight,
          child: ElevatedButton(
            onPressed: onTryPro,
            style: ElevatedButton.styleFrom(
              backgroundColor: DanderColors.secondary,
              foregroundColor: DanderColors.onSecondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  DanderSpacing.borderRadiusMd,
                ),
              ),
              elevation: 0,
            ),
            child: Text(
              'Try Pro free for 7 days',
              style: DanderTextStyles.titleMedium.copyWith(
                color: DanderColors.onSecondary,
              ),
            ),
          ),
        ),
        const SizedBox(height: DanderSpacing.md),

        // "Done for today" — outlined, same height, equal visual weight.
        SizedBox(
          height: _buttonHeight,
          child: OutlinedButton(
            onPressed: onDone,
            style: OutlinedButton.styleFrom(
              foregroundColor: DanderColors.onSurface,
              side: const BorderSide(
                color: DanderColors.cardBorder,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  DanderSpacing.borderRadiusMd,
                ),
              ),
            ),
            child: Text(
              'Done for today',
              style: DanderTextStyles.titleMedium,
            ),
          ),
        ),
      ],
    );
  }
}
