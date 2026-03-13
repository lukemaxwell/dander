import 'package:flutter/material.dart';

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
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: colors.background,
          border: Border.all(color: colors.border, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: colors.text,
                  fontSize: 15,
                  fontWeight: state == ChoiceButtonState.correct
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ),
            if (state == ChoiceButtonState.correct)
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
            if (state == ChoiceButtonState.incorrect)
              const Icon(Icons.cancel, color: Colors.red, size: 20),
          ],
        ),
      ),
    );
  }

  _ButtonColors _resolveColors(ChoiceButtonState s) {
    switch (s) {
      case ChoiceButtonState.unanswered:
        return const _ButtonColors(
          background: Color(0xFF1E1E2E),
          border: Color(0xFF7C3AED),
          text: Colors.white,
        );
      case ChoiceButtonState.correct:
        return const _ButtonColors(
          background: Color(0xFF0F2E1A),
          border: Colors.green,
          text: Colors.green,
        );
      case ChoiceButtonState.incorrect:
        return const _ButtonColors(
          background: Color(0xFF2E0F0F),
          border: Colors.red,
          text: Colors.red,
        );
      case ChoiceButtonState.disabled:
        return const _ButtonColors(
          background: Color(0xFF12121F),
          border: Colors.white12,
          text: Colors.white38,
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
