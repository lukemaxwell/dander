import 'package:flutter/material.dart';
import 'package:dander/core/discoveries/discovery.dart';
import 'package:dander/core/theme/app_theme.dart';
import 'package:dander/core/theme/rarity_colors.dart';
import 'package:dander/features/discoveries/presentation/widgets/category_progress_section.dart';
import 'package:dander/features/discoveries/presentation/widgets/discovery_card.dart';
import 'package:dander/features/discoveries/presentation/widgets/discovery_detail_sheet.dart';
import 'package:dander/features/discoveries/presentation/widgets/rarity_legend.dart';
import 'package:dander/shared/widgets/pressable.dart';

/// The collection screen — shows all found discoveries with filter chips.
class DiscoveriesScreen extends StatefulWidget {
  const DiscoveriesScreen({
    super.key,
    required this.discoveries,
    this.allPois = const [],
    this.zoneName,
  });

  /// All discovered POIs to display.
  final List<Discovery> discoveries;

  /// All cached POIs (including undiscovered) for category progress display.
  final List<Discovery> allPois;

  /// Name of the active zone — shown in exploration hints.
  final String? zoneName;

  @override
  State<DiscoveriesScreen> createState() => _DiscoveriesScreenState();
}

class _DiscoveriesScreenState extends State<DiscoveriesScreen> {
  RarityTier? _selectedRarity;
  String? _selectedCategory;

  List<Discovery> get _filtered {
    return widget.discoveries.where((d) {
      final rarityMatch =
          _selectedRarity == null || d.rarity == _selectedRarity;
      final categoryMatch =
          _selectedCategory == null || d.category == _selectedCategory;
      return rarityMatch && categoryMatch;
    }).toList();
  }

  List<String> get _categories {
    final seen = <String>{};
    final result = <String>[];
    for (final d in widget.discoveries) {
      if (seen.add(d.category)) result.add(d.category);
    }
    return result;
  }

  String _buildCountHeader() {
    final total = widget.discoveries.length;
    final rare =
        widget.discoveries.where((d) => d.rarity == RarityTier.rare).length;
    final uncommon =
        widget.discoveries.where((d) => d.rarity == RarityTier.uncommon).length;
    final common =
        widget.discoveries.where((d) => d.rarity == RarityTier.common).length;
    return '$total discoveries — $rare Rare, $uncommon Uncommon, $common Common';
  }

  /// Per-category count string: "cafe: 2 · park: 1 · ..."
  String _buildCategoryProgress() {
    final counts = <String, int>{};
    for (final d in widget.discoveries) {
      counts[d.category] = (counts[d.category] ?? 0) + 1;
    }
    return counts.entries.map((e) => '${e.key}: ${e.value}').join(' · ');
  }

  void _showDetail(Discovery discovery) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: DanderColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DanderSpacing.borderRadiusLg),
        ),
      ),
      builder: (_) => DiscoveryDetailSheet(discovery: discovery),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: DanderColors.surfaceElevated,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Count header
          if (widget.discoveries.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DanderSpacing.lg,
                DanderSpacing.sm,
                DanderSpacing.lg,
                0,
              ),
              child: Text(
                _buildCountHeader(),
                style: DanderTextStyles.bodySmall,
              ),
            ),
          // Collection progress (per-category counts)
          if (widget.discoveries.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DanderSpacing.lg,
                DanderSpacing.xs,
                DanderSpacing.lg,
                0,
              ),
              child: Text(
                _buildCategoryProgress(),
                style: DanderTextStyles.labelSmall.copyWith(
                  color: DanderColors.onSurfaceMuted,
                ),
              ),
            ),
          // Category progress (silhouettes + found counts)
          if (widget.allPois.isNotEmpty)
            CategoryProgressSection(
              discovered: widget.discoveries,
              allPois: widget.allPois,
              zoneName: widget.zoneName,
            ),
          // Rarity legend
          if (widget.discoveries.isNotEmpty) const RarityLegend(),
          // Filter chips
          if (widget.discoveries.isNotEmpty)
            _FilterRow(
              selectedRarity: _selectedRarity,
              selectedCategory: _selectedCategory,
              categories: _categories,
              onRarityChanged: (rarity) =>
                  setState(() => _selectedRarity = rarity),
              onCategoryChanged: (category) =>
                  setState(() => _selectedCategory = category),
            ),
          // Content
          Expanded(
            child: filtered.isEmpty && widget.discoveries.isEmpty
                ? const _EmptyState()
                : filtered.isEmpty
                    ? Center(
                        child: Text(
                          'No discoveries match the selected filters.',
                          style: DanderTextStyles.bodyMediumMuted,
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        padding: DanderSpacing.pagePadding,
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final discovery = filtered[index];
                          final number =
                              widget.discoveries.indexOf(discovery) + 1;
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: DanderSpacing.md,
                            ),
                            child: Pressable(
                              onTap: () => _showDetail(discovery),
                              child: DiscoveryCard(
                                discovery: discovery,
                                discoveryNumber: number,
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
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
              Icons.explore_off,
              color: DanderColors.onSurfaceDisabled,
              size: 64,
            ),
            const SizedBox(height: DanderSpacing.lg),
            Text(
              'No discoveries yet — go for a walk!',
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

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.selectedRarity,
    required this.selectedCategory,
    required this.categories,
    required this.onRarityChanged,
    required this.onCategoryChanged,
  });

  final RarityTier? selectedRarity;
  final String? selectedCategory;
  final List<String> categories;
  final ValueChanged<RarityTier?> onRarityChanged;
  final ValueChanged<String?> onCategoryChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: DanderSpacing.md,
        vertical: DanderSpacing.sm,
      ),
      child: Row(
        children: [
          // Rarity chips
          for (final tier in RarityTier.values)
            Padding(
              padding: const EdgeInsets.only(right: DanderSpacing.sm),
              child: FilterChip(
                label: Text(RarityColors.label(tier)),
                selected: selectedRarity == tier,
                selectedColor:
                    RarityColors.forTier(tier).withValues(alpha: 0.3),
                checkmarkColor: RarityColors.forTier(tier),
                labelStyle: TextStyle(
                  color: selectedRarity == tier
                      ? RarityColors.forTier(tier)
                      : DanderColors.onSurfaceMuted,
                ),
                backgroundColor: DanderColors.cardBackground,
                side: BorderSide(
                  color: selectedRarity == tier
                      ? RarityColors.forTier(tier)
                      : DanderColors.divider,
                ),
                onSelected: (selected) {
                  onRarityChanged(selected ? tier : null);
                },
              ),
            ),
          // Category chips
          for (final category in categories)
            Padding(
              padding: const EdgeInsets.only(right: DanderSpacing.sm),
              child: FilterChip(
                label: Text(category),
                selected: selectedCategory == category,
                selectedColor: DanderColors.onSurface.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  color: selectedCategory == category
                      ? DanderColors.onSurface
                      : DanderColors.onSurfaceMuted,
                ),
                backgroundColor: DanderColors.cardBackground,
                side: BorderSide(
                  color: selectedCategory == category
                      ? DanderColors.onSurface
                      : DanderColors.divider,
                ),
                onSelected: (selected) {
                  onCategoryChanged(selected ? category : null);
                },
              ),
            ),
        ],
      ),
    );
  }
}
