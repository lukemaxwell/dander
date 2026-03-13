import 'package:flutter/material.dart';

import 'package:dander/core/theme/app_theme.dart';
import 'package:dander/core/zone/zone.dart';
import 'package:dander/core/zone/zone_repository.dart';
import 'package:dander/features/zones/presentation/widgets/zone_card.dart';

/// Screen that lists all zones loaded from [ZoneRepository].
///
/// - Shows a loading spinner while the future resolves.
/// - Shows an empty state when no zones exist.
/// - Renders a [ZoneCard] per zone, highlighting [activeZoneId].
/// - Fires [onZoneTapped] with the zone id when a card is tapped.
class ZonesScreen extends StatefulWidget {
  const ZonesScreen({
    super.key,
    required this.repository,
    this.activeZoneId,
    this.onZoneTapped,
  });

  /// Data source for zone persistence.
  final ZoneRepository repository;

  /// Id of the zone to highlight as currently active (may be null).
  final String? activeZoneId;

  /// Called when the user taps a zone card.
  final void Function(String id)? onZoneTapped;

  @override
  State<ZonesScreen> createState() => _ZonesScreenState();
}

class _ZonesScreenState extends State<ZonesScreen> {
  late Future<List<Zone>> _zonesFuture;

  @override
  void initState() {
    super.initState();
    _zonesFuture = widget.repository.loadAll();
  }

  void _reload() {
    setState(() {
      _zonesFuture = widget.repository.loadAll();
    });
  }

  Future<void> _confirmDelete(Zone zone) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DanderColors.surfaceElevated,
        title: Text('Delete ${zone.name}?', style: DanderTextStyles.titleMedium),
        content: Text(
          'This will permanently delete this zone and all its progress — '
          'including ${zone.xp} XP, walked streets, and quiz history. '
          'This cannot be undone.',
          style: DanderTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: DanderTextStyles.labelLarge.copyWith(
                color: DanderColors.onSurfaceMuted,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Delete',
              style: DanderTextStyles.labelLarge.copyWith(
                color: DanderColors.error,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.repository.delete(zone.id);
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DanderColors.surfaceElevated,
      appBar: AppBar(
        backgroundColor: DanderColors.surfaceElevated,
        foregroundColor: DanderColors.onSurface,
        title: Text('Zones', style: DanderTextStyles.titleLarge),
        elevation: 0,
      ),
      body: FutureBuilder<List<Zone>>(
        future: _zonesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Failed to load zones.',
                style: DanderTextStyles.bodyMediumMuted,
              ),
            );
          }

          final zones = snapshot.data ?? const [];

          if (zones.isEmpty) {
            return const _EmptyState();
          }

          return _ZoneList(
            zones: zones,
            activeZoneId: widget.activeZoneId,
            onZoneTapped: widget.onZoneTapped,
            onZoneDelete: _confirmDelete,
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: DanderSpacing.pagePadding.copyWith(
          top: DanderSpacing.xxxl,
          bottom: DanderSpacing.xxxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.map_outlined,
              color: DanderColors.onSurfaceDisabled,
              size: 64,
            ),
            const SizedBox(height: DanderSpacing.lg),
            Text(
              'Start walking to create your first zone!',
              style: DanderTextStyles.bodyMediumMuted.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Zone list
// ---------------------------------------------------------------------------

class _ZoneList extends StatelessWidget {
  const _ZoneList({
    required this.zones,
    required this.activeZoneId,
    required this.onZoneTapped,
    required this.onZoneDelete,
  });

  final List<Zone> zones;
  final String? activeZoneId;
  final void Function(String id)? onZoneTapped;
  final void Function(Zone zone) onZoneDelete;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: DanderSpacing.pagePadding,
      itemCount: zones.length,
      separatorBuilder: (_, __) => const SizedBox(height: DanderSpacing.md),
      itemBuilder: (context, index) {
        final zone = zones[index];
        final isActive = zone.id == activeZoneId;
        return ZoneCard(
          zone: zone,
          isActive: isActive,
          onTap: () => onZoneTapped?.call(zone.id),
          onDelete: () => onZoneDelete(zone),
        );
      },
    );
  }
}
