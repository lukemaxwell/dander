import 'package:flutter/material.dart';

import 'package:dander/core/theme/dander_colors.dart';
import 'package:dander/core/theme/dander_elevation.dart';
import 'package:dander/core/theme/dander_spacing.dart';
import 'package:dander/core/theme/dander_text_styles.dart';
import 'package:dander/shared/widgets/pressable.dart';

/// A subscription plan card (annual or monthly).
///
/// [isHighlighted] true = annual plan treatment:
///   - 1.5px [DanderColors.secondary] border + [DanderElevation.accentGlow]
///   - Filled amber CTA button
///
/// [isHighlighted] false = monthly plan treatment:
///   - 0.5px [DanderColors.cardBorder] border, no glow
///   - Outlined CTA button
///
/// During purchase, [isLoading] replaces the CTA label with a
/// [CircularProgressIndicator] (20px) and disables taps.
///
/// [errorMessage] displays inline below the CTA in [DanderColors.error].
class PlanCard extends StatelessWidget {
  const PlanCard({
    super.key,
    required this.price,
    required this.period,
    required this.subtitle,
    required this.ctaLabel,
    required this.isHighlighted,
    required this.isLoading,
    required this.onTap,
    this.errorMessage,
  });

  /// Main price string, e.g. "\$34.99/year".
  final String price;

  /// Billing period label, e.g. "year" or "month".
  final String period;

  /// Supporting text, e.g. "\$2.92/mo · 7 days free".
  final String subtitle;

  /// CTA button text, e.g. "Start free trial" or "Subscribe".
  final String ctaLabel;

  /// When true, renders with amber border, accent glow, and filled CTA.
  final bool isHighlighted;

  /// When true, shows [CircularProgressIndicator] in place of [ctaLabel].
  final bool isLoading;

  /// Called when the CTA is tapped (unless [isLoading] is true).
  final VoidCallback onTap;

  /// Optional inline error message shown below the CTA.
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      hint: 'Double-tap to select this plan',
      child: Pressable(
        enabled: !isLoading,
        onTap: isLoading ? null : onTap,
        child: Container(
          decoration: BoxDecoration(
            color: DanderColors.cardBackground,
            borderRadius:
                BorderRadius.circular(DanderSpacing.borderRadiusLg),
            border: Border.all(
              color: isHighlighted
                  ? DanderColors.secondary
                  : DanderColors.cardBorder,
              width: isHighlighted ? 1.5 : 0.5,
            ),
            boxShadow: isHighlighted ? DanderElevation.accentGlow : null,
          ),
          padding: DanderSpacing.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                price,
                style: isHighlighted
                    ? DanderTextStyles.titleLarge
                    : DanderTextStyles.titleMedium.copyWith(
                        color: DanderColors.onSurfaceMuted,
                      ),
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: DanderSpacing.xs),
                Text(
                  subtitle,
                  style: DanderTextStyles.bodySmall,
                ),
              ],
              const SizedBox(height: DanderSpacing.md),
              _CtaButton(
                label: ctaLabel,
                isHighlighted: isHighlighted,
                isLoading: isLoading,
                onTap: onTap,
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: DanderSpacing.sm),
                Text(
                  errorMessage!,
                  style: DanderTextStyles.bodySmall.copyWith(
                    color: DanderColors.error,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private CTA button
// ---------------------------------------------------------------------------

class _CtaButton extends StatelessWidget {
  const _CtaButton({
    required this.label,
    required this.isHighlighted,
    required this.isLoading,
    required this.onTap,
  });

  final String label;
  final bool isHighlighted;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const buttonHeight = 52.0;

    final child = isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor:
                  AlwaysStoppedAnimation<Color>(DanderColors.onSurface),
            ),
          )
        : Text(
            label,
            style: DanderTextStyles.titleMedium.copyWith(
              color: isHighlighted
                  ? DanderColors.onSecondary
                  : DanderColors.onSurface,
            ),
          );

    if (isHighlighted) {
      return SizedBox(
        width: double.infinity,
        height: buttonHeight,
        child: ElevatedButton(
          onPressed: isLoading ? null : onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: DanderColors.secondary,
            disabledBackgroundColor: DanderColors.secondary,
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(DanderSpacing.borderRadiusMd),
            ),
            elevation: 0,
          ),
          child: child,
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: buttonHeight,
      child: OutlinedButton(
        onPressed: isLoading ? null : onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(
            color: DanderColors.cardBorder,
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(DanderSpacing.borderRadiusMd),
          ),
        ),
        child: child,
      ),
    );
  }
}
