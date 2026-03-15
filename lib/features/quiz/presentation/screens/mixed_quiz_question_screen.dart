import 'package:flutter/material.dart';

import 'package:dander/core/quiz/generated_question.dart';
import 'package:dander/core/theme/app_theme.dart';
import 'package:dander/features/quiz/presentation/widgets/choice_button.dart';
import 'package:dander/features/quiz/presentation/widgets/question_type_header.dart';

/// Screen that renders a sequence of [GeneratedQuestion] objects.
///
/// Supports all question types with type-specific visual headers.
/// Calls [onComplete] with the number of correct answers when finished.
class MixedQuizQuestionScreen extends StatefulWidget {
  const MixedQuizQuestionScreen({
    super.key,
    required this.questions,
    required this.onComplete,
  });

  final List<GeneratedQuestion> questions;
  final void Function(int correctCount) onComplete;

  @override
  State<MixedQuizQuestionScreen> createState() =>
      _MixedQuizQuestionScreenState();
}

class _MixedQuizQuestionScreenState extends State<MixedQuizQuestionScreen> {
  int _currentIndex = 0;
  int _correctCount = 0;
  int? _selectedIndex;

  GeneratedQuestion get _currentQuestion => widget.questions[_currentIndex];

  bool get _isComplete => _currentIndex >= widget.questions.length;

  void _onChoiceTap(int index) {
    if (_selectedIndex != null) return;
    setState(() {
      _selectedIndex = index;
      if (index == _currentQuestion.correctIndex) {
        _correctCount++;
      }
    });
  }

  void _onNext() {
    final nextIndex = _currentIndex + 1;

    if (nextIndex >= widget.questions.length) {
      widget.onComplete(_correctCount);
      return;
    }

    setState(() {
      _currentIndex = nextIndex;
      _selectedIndex = null;
    });
  }

  ChoiceButtonState _stateFor(int index) {
    if (_selectedIndex == null) return ChoiceButtonState.unanswered;
    final correctIndex = _currentQuestion.correctIndex;
    if (index == correctIndex) return ChoiceButtonState.correct;
    if (index == _selectedIndex) return ChoiceButtonState.incorrect;
    return ChoiceButtonState.disabled;
  }

  @override
  Widget build(BuildContext context) {
    if (_isComplete) return const SizedBox.shrink();

    final question = _currentQuestion;
    final progress = '${_currentIndex + 1} / ${widget.questions.length}';

    return Scaffold(
      backgroundColor: DanderColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DanderSpacing.xl,
              vertical: DanderSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Progress
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    QuestionTypeHeader(type: question.type),
                    Text(progress, style: DanderTextStyles.labelSmall),
                  ],
                ),
                const SizedBox(height: DanderSpacing.xl),
                // Progress bar
                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(DanderSpacing.borderRadiusSm),
                  child: LinearProgressIndicator(
                    value: (_currentIndex + 1) / widget.questions.length,
                    backgroundColor: DanderColors.divider,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      DanderColors.accent,
                    ),
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: DanderSpacing.xxl),
                // Prompt
                Text(
                  question.prompt,
                  style: DanderTextStyles.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: DanderSpacing.xxl),
                // Choices
                for (var i = 0; i < question.choices.length; i++) ...[
                  ChoiceButton(
                    label: question.choices[i],
                    state: _stateFor(i),
                    onTap: () => _onChoiceTap(i),
                  ),
                  if (i < question.choices.length - 1)
                    const SizedBox(height: DanderSpacing.md - 2),
                ],
                // Next button
                if (_selectedIndex != null) ...[
                  const SizedBox(height: DanderSpacing.xl),
                  SizedBox(
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
                      child: Text('Next', style: DanderTextStyles.labelLarge),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
