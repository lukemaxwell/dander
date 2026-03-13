import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:dander/features/map/presentation/widgets/exploration_badge.dart';

/// The primary screen showing the fog-of-war map centred on the user's location.
///
/// For Issue #1 this is a skeleton that renders a basic [FlutterMap] centred
/// on a default location (London). Location tracking and fog rendering are
/// implemented in subsequent issues.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Default centre: Central London — replaced with real location in Issue #3.
  static const LatLng _defaultCenter = LatLng(51.5074, -0.1278);
  static const double _defaultZoom = 15.0;

  // Placeholder exploration percentage — wired to real data in Issue #7.
  static const int _explorationPercentage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [_buildMap(), _buildFogPlaceholder(), _buildOverlays()],
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      options: const MapOptions(
        initialCenter: _defaultCenter,
        initialZoom: _defaultZoom,
        minZoom: 10,
        maxZoom: 18,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.dander.dander',
          maxNativeZoom: 18,
        ),
      ],
    );
  }

  /// Semi-transparent fog overlay placeholder.
  /// Will be replaced by the proper CustomPainter fog in Issue #2.
  Widget _buildFogPlaceholder() {
    return IgnorePointer(child: Container(color: const Color(0x881A1A2E)));
  }

  Widget _buildOverlays() {
    return const SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(12),
            child: ExplorationBadge(percentageExplored: _explorationPercentage),
          ),
        ],
      ),
    );
  }
}
