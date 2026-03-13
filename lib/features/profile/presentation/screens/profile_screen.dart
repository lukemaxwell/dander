import 'package:flutter/material.dart';
import 'package:dander/core/discoveries/discovery.dart';
import 'package:dander/core/theme/rarity_colors.dart';

/// Profile screen showing user stats including discovery breakdown.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.discoveries,
  });

  /// All discoveries the user has collected.
  final List<Discovery> discoveries;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12121F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12121F),
        foregroundColor: Colors.white,
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _DiscoveryStatsSection(discoveries: discoveries),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Discovery stats section
// ---------------------------------------------------------------------------

class _DiscoveryStatsSection extends StatelessWidget {
  const _DiscoveryStatsSection({required this.discoveries});

  final List<Discovery> discoveries;

  int _count(RarityTier tier) =>
      discoveries.where((d) => d.rarity == tier).length;

  @override
  Widget build(BuildContext context) {
    final total = discoveries.length;
    final rareCount = _count(RarityTier.rare);
    final uncommonCount = _count(RarityTier.uncommon);
    final commonCount = _count(RarityTier.common);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Discoveries',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$total total',
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 16),
          _RarityRow(
            tier: RarityTier.rare,
            count: rareCount,
          ),
          const SizedBox(height: 8),
          _RarityRow(
            tier: RarityTier.uncommon,
            count: uncommonCount,
          ),
          const SizedBox(height: 8),
          _RarityRow(
            tier: RarityTier.common,
            count: commonCount,
          ),
        ],
      ),
    );
  }
}

class _RarityRow extends StatelessWidget {
  const _RarityRow({required this.tier, required this.count});

  final RarityTier tier;
  final int count;

  @override
  Widget build(BuildContext context) {
    final color = RarityColors.forTier(tier);
    final label = RarityColors.label(tier);

    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        Text(
          '$count',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
