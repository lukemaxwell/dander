import 'package:flutter/material.dart';
import 'package:dander/core/theme/app_theme.dart';

/// Consistent screen-level header used at the top of all main screens.
///
/// Renders the screen [title] in [DanderTextStyles.headlineSmall] (Space
/// Grotesk) with an optional [subtitle] beneath it in [DanderTextStyles.bodySmall].
///
/// Includes top safe-area padding automatically.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;

  /// Optional widget anchored to the right of the title row (e.g. an icon button).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        DanderSpacing.lg,
        topPad + DanderSpacing.lg,
        DanderSpacing.lg,
        0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: DanderTextStyles.headlineSmall),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: DanderTextStyles.bodySmall),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
