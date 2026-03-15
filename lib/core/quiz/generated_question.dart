import 'question_type.dart';

/// A quiz question generated from the user's exploration data.
///
/// Unlike [QuizQuestion] (street-only), this supports all question types.
/// Each question has a [type], a human-readable [prompt], a list of
/// [choices], and the [correctIndex] identifying the right answer.
class GeneratedQuestion {
  const GeneratedQuestion({
    required this.questionId,
    required this.type,
    required this.prompt,
    required this.choices,
    required this.correctIndex,
  });

  /// Unique ID encoding type and subject, e.g. `direction:node/1-node/2`.
  final String questionId;

  /// The kind of question being asked.
  final QuestionType type;

  /// The question text shown to the user.
  final String prompt;

  /// The answer options (typically 4).
  final List<String> choices;

  /// Index in [choices] of the correct answer.
  final int correctIndex;
}
