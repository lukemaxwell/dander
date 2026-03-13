import 'package:flutter/material.dart';

/// Identifies each badge in the system.
enum BadgeId {
  firstDander,
  explorer,
  pathfinder,
  localLegend,
  cartographer,
  omniscient,
}

/// An immutable badge that may be locked or unlocked.
///
/// Call [unlock] to obtain a new [Badge] instance with [unlockedAt] set.
class Badge {
  const Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.requiredExplorationPct,
    required this.icon,
    this.unlockedAt,
  });

  final BadgeId id;
  final String name;
  final String description;

  /// Exploration fraction (0.0–1.0) required to unlock this badge.
  final double requiredExplorationPct;

  final IconData icon;

  /// The moment this badge was unlocked; `null` when still locked.
  final DateTime? unlockedAt;

  bool get isUnlocked => unlockedAt != null;

  /// Returns a new [Badge] with [unlockedAt] set to [at].
  Badge unlock(DateTime at) => Badge(
        id: id,
        name: name,
        description: description,
        requiredExplorationPct: requiredExplorationPct,
        icon: icon,
        unlockedAt: at,
      );

  /// Returns a copy with optionally overridden fields.
  Badge copyWith({
    BadgeId? id,
    String? name,
    String? description,
    double? requiredExplorationPct,
    IconData? icon,
    DateTime? unlockedAt,
  }) =>
      Badge(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        requiredExplorationPct:
            requiredExplorationPct ?? this.requiredExplorationPct,
        icon: icon ?? this.icon,
        unlockedAt: unlockedAt ?? this.unlockedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id.name,
        'unlockedAt': unlockedAt?.toIso8601String(),
      };

  /// Restores a [Badge] from JSON, merging persisted unlock state into the
  /// static badge definition.
  static Badge fromJson(Map<String, dynamic> json, Badge definition) {
    final unlockedAtRaw = json['unlockedAt'] as String?;
    final unlockedAt =
        unlockedAtRaw != null ? DateTime.parse(unlockedAtRaw) : null;
    if (unlockedAt != null) return definition.unlock(unlockedAt);
    return definition;
  }
}

/// Static badge definitions — locked state, all 6 badges in ascending order.
class BadgeDefinitions {
  BadgeDefinitions._();

  static const List<Badge> badges = [
    Badge(
      id: BadgeId.firstDander,
      name: 'First Dander',
      description: 'Complete your first walk',
      requiredExplorationPct: 0.0,
      icon: Icons.directions_walk,
    ),
    Badge(
      id: BadgeId.explorer,
      name: 'Explorer',
      description: 'Explore 10% of your neighbourhood',
      requiredExplorationPct: 0.10,
      icon: Icons.explore,
    ),
    Badge(
      id: BadgeId.pathfinder,
      name: 'Pathfinder',
      description: 'Explore 25% of your neighbourhood',
      requiredExplorationPct: 0.25,
      icon: Icons.map,
    ),
    Badge(
      id: BadgeId.localLegend,
      name: 'Local Legend',
      description: 'Explore 50% of your neighbourhood',
      requiredExplorationPct: 0.50,
      icon: Icons.star,
    ),
    Badge(
      id: BadgeId.cartographer,
      name: 'Cartographer',
      description: 'Explore 75% of your neighbourhood',
      requiredExplorationPct: 0.75,
      icon: Icons.layers,
    ),
    Badge(
      id: BadgeId.omniscient,
      name: 'Omniscient',
      description: 'Explore 100% of your neighbourhood',
      requiredExplorationPct: 1.0,
      icon: Icons.emoji_events,
    ),
  ];
}
