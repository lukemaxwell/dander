import 'package:flutter/material.dart';

import 'package:dander/core/theme/app_theme.dart';

/// Screen displaying the user's collected discoveries.
///
/// Issue #1 skeleton: shows an empty-state placeholder.
/// Discovery collection and filtering are implemented in Issue #5.
class DiscoveriesScreen extends StatelessWidget {
  const DiscoveriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DanderColors.surface,
      appBar: AppBar(title: const Text('Discoveries')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.explore_off,
              size: 64,
              color: DanderColors.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            const Text(
              'No discoveries yet',
              style: TextStyle(
                color: DanderColors.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start exploring to find hidden spots',
              style: TextStyle(
                color: DanderColors.onSurface.withValues(alpha: 0.6),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
