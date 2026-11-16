import 'package:flutter/material.dart';

import '../../domain/models/garment.dart';

class FilterBar extends StatelessWidget {
  const FilterBar({
    super.key,
    this.selectedCategory,
    this.selectedOccasion,
    this.selectedSeason,
    required this.onCategoryChanged,
    required this.onOccasionChanged,
    required this.onSeasonChanged,
  });

  final GarmentCategory? selectedCategory;
  final Occasion? selectedOccasion;
  final Season? selectedSeason;
  final ValueChanged<GarmentCategory?> onCategoryChanged;
  final ValueChanged<Occasion?> onOccasionChanged;
  final ValueChanged<Season?> onSeasonChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          ...GarmentCategory.values.map(
            (category) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                showCheckmark: false,
                label: Text(category.label),
                selected: selectedCategory == category,
                onSelected: (_) => onCategoryChanged(
                  selectedCategory == category ? null : category,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          ...Occasion.values.map(
            (occasion) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                showCheckmark: false,
                label: Text(occasion.label),
                selected: selectedOccasion == occasion,
                onSelected: (_) => onOccasionChanged(
                  selectedOccasion == occasion ? null : occasion,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          ...Season.values.map(
            (season) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                showCheckmark: false,
                label: Text(season.label),
                selected: selectedSeason == season,
                onSelected: (_) => onSeasonChanged(
                  selectedSeason == season ? null : season,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
