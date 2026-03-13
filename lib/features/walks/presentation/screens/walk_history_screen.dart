import 'package:flutter/material.dart';
import 'package:dander/core/location/walk_session.dart';
import 'package:dander/core/location/walk_stats_formatter.dart';
import 'package:dander/features/walks/presentation/widgets/walk_mini_map.dart';

// ---------------------------------------------------------------------------
// Month name helper
// ---------------------------------------------------------------------------

const _monthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _formatDate(DateTime dt) =>
    '${dt.day} ${_monthNames[dt.month - 1]} ${dt.year}';

/// Screen showing a chronological list of past walk sessions.
///
/// Each row displays date, duration, distance, and discovery count.
/// Tapping a row expands it to show a [WalkMiniMap] of the route.
///
/// When [walks] is empty an encouraging empty-state message is shown.
class WalkHistoryScreen extends StatefulWidget {
  const WalkHistoryScreen({
    super.key,
    required this.walks,
  });

  /// All past walk sessions, shown newest-first.
  final List<WalkSession> walks;

  @override
  State<WalkHistoryScreen> createState() => _WalkHistoryScreenState();
}

class _WalkHistoryScreenState extends State<WalkHistoryScreen> {
  String? _expandedId;

  @override
  Widget build(BuildContext context) {
    // Sort newest first (defensive copy — immutability).
    final sorted = [...widget.walks]
      ..sort((a, b) => b.startTime.compareTo(a.startTime));

    return Scaffold(
      backgroundColor: const Color(0xFF12121F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12121F),
        foregroundColor: Colors.white,
        title: const Text(
          'Walk History',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: sorted.isEmpty
          ? _EmptyState()
          : _WalkList(
              walks: sorted,
              expandedId: _expandedId,
              onTap: (id) => setState(() {
                _expandedId = _expandedId == id ? null : id;
              }),
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions_walk, color: Colors.white24, size: 64),
            SizedBox(height: 16),
            Text(
              'No walks yet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Tap Start Walk on the map to begin\nyour first exploration.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white54,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Walk list
// ---------------------------------------------------------------------------

class _WalkList extends StatelessWidget {
  const _WalkList({
    required this.walks,
    required this.expandedId,
    required this.onTap,
  });

  final List<WalkSession> walks;
  final String? expandedId;
  final void Function(String id) onTap;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: walks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final walk = walks[index];
        return _WalkRow(
          walk: walk,
          isExpanded: expandedId == walk.id,
          onTap: () => onTap(walk.id),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Individual walk row
// ---------------------------------------------------------------------------

class _WalkRow extends StatelessWidget {
  const _WalkRow({
    required this.walk,
    required this.isExpanded,
    required this.onTap,
  });

  final WalkSession walk;
  final bool isExpanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dateLabel = _formatDate(walk.startTime);
    final duration = WalkStatsFormatter.formatDuration(walk.duration);
    final distance = WalkStatsFormatter.formatDistance(walk.distanceMeters);
    final routePoints = walk.points.map((p) => p.position).toList();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            onTap: onTap,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            title: Text(
              dateLabel,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              '$duration · $distance',
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
            trailing: Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              color: Colors.white38,
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: SizedBox(
                height: 160,
                child: WalkMiniMap(points: routePoints),
              ),
            ),
        ],
      ),
    );
  }
}
