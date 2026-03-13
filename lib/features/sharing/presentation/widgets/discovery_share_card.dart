import 'package:flutter/material.dart';

import '../../../discoveries/domain/models/discovery.dart';

/// Shareable card for an individual discovery.
///
/// Fixed size 1080x1350 (portrait, optimised for Instagram Stories / 4:5).
/// Shows Dander branding at the top, the discovery details in the centre,
/// and the dander.app watermark at the bottom.
class DiscoveryShareCard extends StatelessWidget {
  const DiscoveryShareCard({super.key, required this.discovery});

  final Discovery discovery;

  static const double cardWidth = 1080;
  static const double cardHeight = 1350;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: cardWidth,
      height: cardHeight,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0F0F1A),
              discovery.rarity.color.withAlpha(51),
            ],
          ),
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildDiscoveryContent()),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(48, 60, 48, 0),
      child: Row(
        children: [
          _DanderLogo(),
          const SizedBox(width: 16),
          const Text(
            'Dander',
            style: TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          const Spacer(),
          const Text(
            'New Discovery!',
            style: TextStyle(
              color: Color(0xFF6C63FF),
              fontSize: 28,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoveryContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _RarityBadge(rarity: discovery.rarity),
          const SizedBox(height: 40),
          Text(
            discovery.name,
            key: const Key('discovery_name'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 64,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(26),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              discovery.category,
              key: const Key('discovery_category'),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 32,
                fontWeight: FontWeight.w500,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 60),
          _DiscoveryStats(discovery: discovery),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(48, 24, 48, 60),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Text(
            'dander.app',
            key: Key('watermark'),
            style: TextStyle(
              color: Colors.white38,
              fontSize: 28,
              fontWeight: FontWeight.w400,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _RarityBadge extends StatelessWidget {
  const _RarityBadge({required this.rarity});

  final Rarity rarity;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
      decoration: BoxDecoration(
        color: rarity.color.withAlpha(51),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: rarity.color, width: 2),
      ),
      child: Text(
        rarity.displayName.toUpperCase(),
        key: const Key('rarity_label'),
        style: TextStyle(
          color: rarity.color,
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: 4,
        ),
      ),
    );
  }
}

class _DiscoveryStats extends StatelessWidget {
  const _DiscoveryStats({required this.discovery});

  final Discovery discovery;

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${discovery.discoveredAt.day}/${discovery.discoveredAt.month}/${discovery.discoveredAt.year}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _StatItem(label: 'Discovered', value: dateStr),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 24,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _DanderLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFF6C63FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Text(
          'D',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
