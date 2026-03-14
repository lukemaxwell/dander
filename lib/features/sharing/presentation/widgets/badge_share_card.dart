import 'package:flutter/material.dart' hide Badge;

import 'package:dander/core/progress/badge.dart';

/// Shareable badge unlock celebration card.
///
/// Fixed size 1080x1350 (portrait, optimised for Instagram Stories / 4:5).
/// Shows badge icon, name, description, unlock date, exploration percentage,
/// and a CTA question for viewers. No location data.
class BadgeShareCard extends StatelessWidget {
  const BadgeShareCard({
    super.key,
    required this.badge,
    required this.explorationPercent,
  });

  final Badge badge;

  /// Current exploration percentage (e.g. 10.0 for 10%).
  final double explorationPercent;

  static const double cardWidth = 1080;
  static const double cardHeight = 1350;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: cardWidth,
      height: cardHeight,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F0F1A), Color(0xFF1A1A2E)],
          ),
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildBadge()),
            _buildTagline(),
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
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF4FC3F7),
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
          ),
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
        ],
      ),
    );
  }

  Widget _buildBadge() {
    final unlockDate = badge.unlockedAt != null
        ? _formatDate(badge.unlockedAt!)
        : '';

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF4FC3F7).withAlpha(26),
              border: Border.all(
                color: const Color(0xFF4FC3F7).withAlpha(77),
                width: 3,
              ),
            ),
            child: Icon(
              badge.icon,
              size: 96,
              color: const Color(0xFF4FC3F7),
            ),
          ),
          const SizedBox(height: 40),
          Text(
            badge.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 56,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            badge.description,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 28,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 32),
          if (unlockDate.isNotEmpty)
            Text(
              'Earned on $unlockDate',
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 24,
                fontWeight: FontWeight.w400,
              ),
            ),
          const SizedBox(height: 8),
          Text(
            '${explorationPercent.toStringAsFixed(1)}%',
            style: const TextStyle(
              color: Color(0xFF4FC3F7),
              fontSize: 36,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Text(
            'explored',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 24,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagline() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 48, vertical: 40),
      child: Text(
        'How well do you know your neighbourhood?',
        key: Key('tagline'),
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white60,
          fontSize: 36,
          fontWeight: FontWeight.w300,
          fontStyle: FontStyle.italic,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(48, 0, 48, 60),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'dander.app',
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

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}
