import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:dander/core/haptics/haptic_service.dart';
import 'package:dander/core/navigation/app_router.dart';
import 'package:dander/core/theme/app_theme.dart';

/// Persistent shell wrapping all top-level routes with a bottom navigation bar.
///
/// The nav bar uses a [BackdropFilter] blur so the map content bleeds through.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith(AppRoutes.discoveries)) return 1;
    if (location.startsWith(AppRoutes.quiz)) return 2;
    if (location.startsWith(AppRoutes.zones)) return 3;
    if (location.startsWith(AppRoutes.profile)) return 4;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    HapticService.navTabSwitch();
    switch (index) {
      case 0:
        context.go(AppRoutes.home);
      case 1:
        context.go(AppRoutes.discoveries);
      case 2:
        context.go(AppRoutes.quiz);
      case 3:
        context.go(AppRoutes.zones);
      case 4:
        context.go(AppRoutes.profile);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex(context);
    return Scaffold(
      extendBody: true,
      body: child,
      bottomNavigationBar: _BlurredNavBar(
        currentIndex: currentIndex,
        onTap: (index) => _onTap(context, index),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Blurred bottom nav bar
// ---------------------------------------------------------------------------

class _BlurredNavBar extends StatelessWidget {
  const _BlurredNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          color: DanderColors.surfaceElevated.withValues(alpha: 0.85),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 64,
              child: Row(
                children: [
                  _NavItem(
                    icon: Icons.map_outlined,
                    activeIcon: Icons.map,
                    label: 'Explore',
                    index: 0,
                    currentIndex: currentIndex,
                    onTap: onTap,
                  ),
                  _NavItem(
                    icon: Icons.star_outline,
                    activeIcon: Icons.star,
                    label: 'Discoveries',
                    index: 1,
                    currentIndex: currentIndex,
                    onTap: onTap,
                  ),
                  _NavItem(
                    icon: Icons.quiz_outlined,
                    activeIcon: Icons.quiz,
                    label: 'Quiz',
                    index: 2,
                    currentIndex: currentIndex,
                    onTap: onTap,
                  ),
                  _NavItem(
                    icon: Icons.public_outlined,
                    activeIcon: Icons.public,
                    label: 'Zones',
                    index: 3,
                    currentIndex: currentIndex,
                    onTap: onTap,
                  ),
                  _NavItem(
                    icon: Icons.person_outline,
                    activeIcon: Icons.person,
                    label: 'Profile',
                    index: 4,
                    currentIndex: currentIndex,
                    onTap: onTap,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final isActive = index == currentIndex;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Active indicator pill behind the icon
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(
                horizontal: DanderSpacing.md,
                vertical: DanderSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: isActive
                    ? DanderColors.accent.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(DanderSpacing.borderRadiusFull),
              ),
              child: Icon(
                isActive ? activeIcon : icon,
                color: isActive
                    ? DanderColors.accent
                    : DanderColors.onSurfaceMuted,
                size: 22,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: DanderTextStyles.labelSmall.copyWith(
                color: isActive
                    ? DanderColors.accent
                    : DanderColors.onSurfaceMuted,
                fontWeight:
                    isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// DanderCard
// ---------------------------------------------------------------------------

/// A themed card with rounded corners, brand background, and elevation shadow.
class DanderCard extends StatelessWidget {
  const DanderCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding ?? DanderSpacing.cardPadding,
      decoration: BoxDecoration(
        color: DanderColors.cardBackground,
        borderRadius: BorderRadius.circular(DanderSpacing.borderRadiusLg),
        boxShadow: DanderElevation.level1,
      ),
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// DanderButton
// ---------------------------------------------------------------------------

/// A themed primary action button with optional leading icon.
class DanderButton extends StatelessWidget {
  const DanderButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;

  /// Optional icon shown to the left of the label.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final bgColor =
        enabled ? DanderColors.secondary : DanderColors.onSurfaceDisabled;
    final fgColor =
        enabled ? DanderColors.onSurface : DanderColors.onSurfaceMuted;

    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: DanderSpacing.xl,
          vertical: DanderSpacing.md,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius:
              BorderRadius.circular(DanderSpacing.borderRadiusFull),
          boxShadow: enabled ? DanderElevation.level1 : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: fgColor, size: 18),
              const SizedBox(width: DanderSpacing.sm),
            ],
            Text(
              label,
              style: DanderTextStyles.labelLarge.copyWith(
                color: fgColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
