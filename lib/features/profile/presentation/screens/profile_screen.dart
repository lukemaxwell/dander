import 'package:flutter/material.dart';

import 'package:dander/core/theme/app_theme.dart';

/// Screen displaying the user's exploration profile and statistics.
///
/// Issue #1 skeleton: shows placeholder stats.
/// Progress tracking, streaks, and badges are implemented in Issue #7.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DanderColors.surface,
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundColor: DanderColors.accent,
              child: Icon(Icons.person, size: 40, color: DanderColors.primary),
            ),
            const SizedBox(height: 24),
            const Text(
              'Explorer',
              style: TextStyle(
                color: DanderColors.onSurface,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '0% neighbourhood explored',
              style: TextStyle(
                color: DanderColors.onSurface.withValues(alpha: 0.7),
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
