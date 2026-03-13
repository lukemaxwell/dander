import 'package:flutter/material.dart';

import 'package:dander/core/quiz/quiz_result.dart';
import 'package:dander/core/quiz/quiz_session.dart';
import 'package:dander/features/quiz/presentation/widgets/choice_button.dart';
import 'package:dander/features/quiz/presentation/widgets/quiz_map_snippet.dart';

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

  @override
  void initState() {
    super.initState();
    _session = widget.session;
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
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Map snippet
              QuizMapSnippet(street: question.targetStreet),
              const SizedBox(height: 16),
              // Question prompt
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'What is this street called?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              // Choices
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
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
                        const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
              // Next button — appears after answering
              if (_selectedIndex != null)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _onNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Next',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
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
