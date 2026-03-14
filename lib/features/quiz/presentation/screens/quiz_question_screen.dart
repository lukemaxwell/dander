import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'package:dander/core/quiz/quiz_result.dart';
import 'package:dander/core/quiz/quiz_session.dart';
import 'package:dander/core/theme/app_theme.dart';
import 'package:dander/core/zone/zone_level.dart';
import 'package:dander/core/zone/zone_repository.dart';
import 'package:dander/core/zone/zone_service.dart';
import 'package:dander/features/quiz/presentation/widgets/choice_button.dart';
import 'package:dander/features/quiz/presentation/widgets/quiz_map_snippet.dart';
import 'package:dander/shared/widgets/floating_xp_text.dart';

/// Screen displaying a single quiz question.
///
/// Top half: [QuizMapSnippet] showing the target street.
/// Bottom half: question prompt + 4 [ChoiceButton] widgets.
///
/// After the user selects an answer:
/// - The correct button turns green.
/// - The selected wrong button turns red.
/// - All other buttons are disabled.
/// - A "Next" button appears to proceed.
///
/// When the session is complete, [onComplete] is called with the final
/// [QuizSession].
class QuizQuestionScreen extends StatefulWidget {
  const QuizQuestionScreen({
    super.key,
    required this.session,
    required this.onComplete,
  });

  final QuizSession session;
  final void Function(QuizSession completedSession) onComplete;

  @override
  State<QuizQuestionScreen> createState() => _QuizQuestionScreenState();
}

class _QuizQuestionScreenState extends State<QuizQuestionScreen> {
  int? _selectedIndex;
  late QuizSession _session;
  final FloatingXpController _xpController = FloatingXpController();

  @override
  void initState() {
    super.initState();
    _session = widget.session;
  }

  @override
  void dispose() {
    _xpController.dispose();
    super.dispose();
  }

  void _onChoiceTap(int index) {
    if (_selectedIndex != null) return; // already answered
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onNext() {
    final question = _session.currentQuestion;
    final result = _selectedIndex == question.correctIndex
        ? QuizResult.correct
        : QuizResult.incorrect;

    _awardQuizXp(result);

    final updated = _session.answerCurrent(result);

    if (updated.isComplete) {
      widget.onComplete(updated);
      return;
    }

    setState(() {
      _session = updated;
      _selectedIndex = null;
    });
  }

  Future<void> _awardQuizXp(QuizResult result) async {
    try {
      final zoneService = GetIt.instance<ZoneService>();
      final zoneRepo = GetIt.instance<ZoneRepository>();
      final zones = await zoneRepo.loadAll();
      if (zones.isEmpty) return;

      // Award XP to the first zone (home zone for now).
      final zoneId = zones.first.id;

      if (result == QuizResult.correct) {
        zoneService.incrementQuizStreak(zoneId);
        final streakBonus = zoneService.isStreakBonusActive(zoneId);
        await zoneService.awardQuizXp(zoneId, isStreakBonus: streakBonus);

        final xpAmount = streakBonus
            ? ZoneLevel.xpPerQuizCorrect + ZoneLevel.xpPerStreakBonus
            : ZoneLevel.xpPerQuizCorrect;
        _xpController.show(xpAmount);
      } else {
        zoneService.resetQuizStreak(zoneId);
      }
    } catch (_) {
      // Zone service not available — skip
    }
  }

  ChoiceButtonState _stateFor(int index) {
    if (_selectedIndex == null) return ChoiceButtonState.unanswered;
    final correctIndex = _session.currentQuestion.correctIndex;
    if (index == correctIndex) return ChoiceButtonState.correct;
    if (index == _selectedIndex) return ChoiceButtonState.incorrect;
    return ChoiceButtonState.disabled;
  }

  @override
  Widget build(BuildContext context) {
    if (_session.isComplete) {
      return const SizedBox.shrink();
    }

    final question = _session.currentQuestion;

    return Scaffold(
      backgroundColor: DanderColors.surface,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Map snippet
                  QuizMapSnippet(street: question.targetStreet),
                  const SizedBox(height: DanderSpacing.lg),
                  // Question prompt
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DanderSpacing.xl,
                    ),
                    child: Text(
                      'What is this street called?',
                      style: DanderTextStyles.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: DanderSpacing.lg),
                  // Choices
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DanderSpacing.xl,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        for (var i = 0; i < question.choices.length; i++) ...[
                          ChoiceButton(
                            label: question.choices[i].name,
                            state: _stateFor(i),
                            onTap: () => _onChoiceTap(i),
                          ),
                          if (i < question.choices.length - 1)
                            const SizedBox(height: DanderSpacing.md - 2),
                        ],
                      ],
                    ),
                  ),
                  // Next button — appears after answering
                  if (_selectedIndex != null)
                    Padding(
                      padding: DanderSpacing.pagePadding,
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _onNext,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: DanderColors.secondary,
                            padding: const EdgeInsets.symmetric(
                              vertical: DanderSpacing.lg,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                DanderSpacing.borderRadiusMd,
                              ),
                            ),
                          ),
                          child: Text(
                            'Next',
                            style: DanderTextStyles.labelLarge,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Floating XP text overlay — positioned near top.
            Positioned(
              top: DanderSpacing.xl,
              left: 0,
              right: 0,
              child: Center(
                child: FloatingXpTextOverlay(controller: _xpController),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
