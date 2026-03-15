import 'package:flutter/material.dart';

import 'package:dander/core/quiz/question_type.dart';
import 'package:dander/core/theme/app_theme.dart';

/// Visual header for a quiz question showing the question type's icon and label.
///
/// Displayed above the question prompt to help the user understand what kind
/// of knowledge is being tested.
class QuestionTypeHeader extends StatelessWidget {
  const QuestionTypeHeader({super.key, required this.type});

  final QuestionType type;

  @override
  Widget build(BuildContext context) {
    final (icon, label) = _typeInfo(type);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: DanderColors.accent),
        const SizedBox(width: DanderSpacing.xs),
        Text(
          label,
          style: DanderTextStyles.labelSmall.copyWith(
            color: DanderColors.accent,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  static (IconData, String) _typeInfo(QuestionType type) => switch (type) {
        QuestionType.streetName => (Icons.map_outlined, 'STREET NAME'),
        QuestionType.direction => (Icons.explore_outlined, 'DIRECTION'),
        QuestionType.proximity => (Icons.near_me_outlined, 'PROXIMITY'),
        QuestionType.category => (Icons.category_outlined, 'CATEGORY'),
        QuestionType.route => (Icons.route_outlined, 'ROUTE'),
      };
}
