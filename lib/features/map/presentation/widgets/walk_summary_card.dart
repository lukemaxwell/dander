import 'package:flutter/material.dart';
import 'package:dander/core/location/walk_session.dart';
import 'package:dander/core/location/walk_stats_formatter.dart';

/// A card shown at the end of a walk summarising key stats.
///
/// Intended to be displayed as a modal bottom sheet (or embedded in a sheet
/// by the caller).  Provides a "Share" placeholder and a "Done" button.
class WalkSummaryCard extends StatelessWidget {
  const WalkSummaryCard({
    super.key,
    required this.session,
    required this.fogClearedPercent,
    required this.discoveriesFound,
    required this.onDone,
    required this.onShare,
  });

  /// The completed [WalkSession].
  final WalkSession session;

  /// Percentage of fog cleared during this walk (0–100).
  final double fogClearedPercent;

  /// Number of new discoveries found during this walk.
  final int discoveriesFound;

  /// Called when the user taps "Done".
  final VoidCallback onDone;

  /// Called when the user taps "Share" (placeholder for Issue #8).
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final duration = WalkStatsFormatter.formatDuration(session.duration);
    final distance = WalkStatsFormatter.formatDistance(session.distanceMeters);
    final fogLabel = WalkStatsFormatter.formatFogCleared(fogClearedPercent);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Title
          const Text(
            'Walk Complete',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          // Stats grid
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatTile(label: 'Duration', value: duration),
              _StatTile(label: 'Distance', value: distance),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatTile(label: 'Fog Cleared', value: fogLabel),
              _StatTile(label: 'Discoveries', value: '$discoveriesFound'),
            ],
          ),
          const SizedBox(height: 28),
          // Share button (placeholder)
          OutlinedButton(
            onPressed: onShare,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF7C3AED),
              side: const BorderSide(color: Color(0xFF7C3AED)),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Share',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 12),
          // Done button
          ElevatedButton(
            onPressed: onDone,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Done',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF12121F),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
