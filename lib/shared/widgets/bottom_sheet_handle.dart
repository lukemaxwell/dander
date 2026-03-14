import 'package:flutter/material.dart';
import 'package:dander/core/theme/app_theme.dart';

/// Standard drag-handle indicator for modal bottom sheets.
///
/// Place at the top of every bottom sheet content column:
/// ```dart
/// Column(
///   mainAxisSize: MainAxisSize.min,
///   children: [
///     const BottomSheetHandle(),
///     // ... rest of content
///   ],
/// )
/// ```
class BottomSheetHandle extends StatelessWidget {
  const BottomSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: DanderSpacing.md, bottom: DanderSpacing.xs),
      child: Center(
        child: Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: DanderColors.onSurfaceMuted.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}
