import 'package:flutter/material.dart';

import 'package:dander/core/theme/app_theme.dart';

/// Visual state of a [ChoiceButton].
enum ChoiceButtonState {
  /// Default — not yet answered.
  unanswered,

  /// This choice was correct (shown after answer submission).
  correct,

  /// This choice was incorrect (the one the user selected wrongly).
  incorrect,

  /// A non-selected button after any answer was submitted.
  disabled,
}

/// A quiz answer choice button.
///
/// Renders with different visual styles depending on [state].
/// When [state] is [ChoiceButtonState.disabled], [onTap] is never called.
class ChoiceButton extends StatelessWidget {
  const ChoiceButton({
    super.key,
    required this.label,
    required this.state,
    required this.onTap,
  });

  final String label;
  final ChoiceButtonState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = _resolveColors(state);

    return GestureDetector(
      onTap: state == ChoiceButtonState.disabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          vertical: DanderSpacing.md + 2,
          horizontal: DanderSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: colors.background,
          border: Border.all(color: colors.border, width: 2),
          borderRadius: BorderRadius.circular(DanderSpacing.borderRadiusMd),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: DanderTextStyles.bodyMedium.copyWith(
                  color: colors.text,
                  fontWeight: state == ChoiceButtonState.correct
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ),
            if (state == ChoiceButtonState.correct)
              Icon(Icons.check_circle, color: DanderColors.success, size: 20),
            if (state == ChoiceButtonState.incorrect)
              Icon(Icons.cancel, color: DanderColors.error, size: 20),
          ],
        ),
      ),
    );
  }

  _ButtonColors _resolveColors(ChoiceButtonState s) {
    switch (s) {
      case ChoiceButtonState.unanswered:
        return _ButtonColors(
          background: DanderColors.cardBackground,
          border: DanderColors.secondary,
          text: DanderColors.onSurface,
        );
      case ChoiceButtonState.correct:
        return _ButtonColors(
          background: DanderColors.success.withValues(alpha: 0.12),
          border: DanderColors.success,
          text: DanderColors.success,
        );
      case ChoiceButtonState.incorrect:
        return _ButtonColors(
          background: DanderColors.error.withValues(alpha: 0.12),
          border: DanderColors.error,
          text: DanderColors.error,
        );
      case ChoiceButtonState.disabled:
        return _ButtonColors(
          background: DanderColors.surface,
          border: DanderColors.divider,
          text: DanderColors.onSurfaceDisabled,
        );
    }
  }
}

@immutable
class _ButtonColors {
  const _ButtonColors({
    required this.background,
    required this.border,
    required this.text,
  });

  final Color background;
  final Color border;
  final Color text;
}
