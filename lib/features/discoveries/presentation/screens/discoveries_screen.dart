import 'package:flutter/material.dart';
import 'package:dander/core/discoveries/discovery.dart';
import 'package:dander/core/theme/rarity_colors.dart';
import 'package:dander/features/discoveries/presentation/widgets/discovery_card.dart';

/// The collection screen — shows all found discoveries with filter chips.
class DiscoveriesScreen extends StatefulWidget {
  const DiscoveriesScreen({
    super.key,
    required this.discoveries,
  });

  /// All discovered POIs to display.
  final List<Discovery> discoveries;

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

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: const Color(0xFF12121F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12121F),
        foregroundColor: Colors.white,
        title: const Text(
          'Discoveries',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Count header
          if (widget.discoveries.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                _buildCountHeader(),
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
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
                    ? const Center(
                        child: Text(
                          'No discoveries match the selected filters.',
                          style: TextStyle(color: Colors.white54),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final discovery = filtered[index];
                          final number =
                              widget.discoveries.indexOf(discovery) + 1;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: DiscoveryCard(
                              discovery: discovery,
                              discoveryNumber: number,
                            ),
                          );
                        },
                      ),
          ),
        ],
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
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.explore_off, color: Colors.white24, size: 64),
            SizedBox(height: 16),
            Text(
              'No discoveries yet — go for a walk!',
              style: TextStyle(
                color: Colors.white54,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // Rarity chips
          for (final tier in RarityTier.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(RarityColors.label(tier)),
                selected: selectedRarity == tier,
                selectedColor:
                    RarityColors.forTier(tier).withValues(alpha: 0.3),
                checkmarkColor: RarityColors.forTier(tier),
                labelStyle: TextStyle(
                  color: selectedRarity == tier
                      ? RarityColors.forTier(tier)
                      : Colors.white70,
                ),
                backgroundColor: const Color(0xFF1E1E2E),
                side: BorderSide(
                  color: selectedRarity == tier
                      ? RarityColors.forTier(tier)
                      : Colors.white24,
                ),
                onSelected: (selected) {
                  onRarityChanged(selected ? tier : null);
                },
              ),
            ),
          // Category chips
          for (final category in categories)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(category),
                selected: selectedCategory == category,
                selectedColor: Colors.white.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  color: selectedCategory == category
                      ? Colors.white
                      : Colors.white70,
                ),
                backgroundColor: const Color(0xFF1E1E2E),
                side: BorderSide(
                  color: selectedCategory == category
                      ? Colors.white
                      : Colors.white24,
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
