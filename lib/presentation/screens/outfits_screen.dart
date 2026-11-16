import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/garment.dart';
import '../../domain/models/outfit.dart';
import '../providers/outfit_providers.dart';
import '../widgets/empty_state.dart';

class OutfitsScreen extends ConsumerWidget {
  const OutfitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(outfitFiltersProvider);
    final outfitsAsync = ref.watch(generatedOutfitsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Looks')),
      body: Column(
        children: [
          _FiltersBar(filters: filters),
          Expanded(
            child: outfitsAsync.when(
              data: (outfits) {
                if (outfits.isEmpty) {
                  return const EmptyState(
                    icon: Icons.auto_awesome_outlined,
                    title: 'Sin combinaciones',
                    message:
                        'Añade más prendas o ajusta los filtros para generar looks.',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: outfits.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) =>
                      _OutfitCard(outfit: outfits[index]),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('Error al generar looks: $e'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FiltersBar extends ConsumerWidget {
  const _FiltersBar({required this.filters});

  final OutfitFilters filters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(outfitFiltersProvider.notifier);
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Todas',
                    selected: filters.occasion == null,
                    onSelected: (_) => notifier.setOccasion(null),
                  ),
                  for (final o in Occasion.values)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _FilterChip(
                        label: o.label,
                        selected: filters.occasion == o,
                        onSelected: (_) => notifier.setOccasion(o),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Todas',
                    selected: filters.season == null,
                    onSelected: (_) => notifier.setSeason(null),
                  ),
                  for (final s in Season.values)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _FilterChip(
                        label: s.label,
                        selected: filters.season == s,
                        onSelected: (_) => notifier.setSeason(s),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _OutfitCard extends StatelessWidget {
  const _OutfitCard({required this.outfit});

  final Outfit outfit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scorePct = (outfit.score * 100).round();
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final g in outfit.garments) _GarmentChip(garment: g),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _ScoreBadge(scorePct: scorePct),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              outfit.explanation,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _GarmentChip extends StatelessWidget {
  const _GarmentChip({required this.garment});

  final Garment garment;

  @override
  Widget build(BuildContext context) {
    final color = garment.colors.isNotEmpty
        ? Color.fromARGB(
            255,
            garment.colors.first.red,
            garment.colors.first.green,
            garment.colors.first.blue,
          )
        : Colors.grey;
    return Chip(
      avatar: CircleAvatar(backgroundColor: color),
      label: Text(garment.category.label),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.scorePct});

  final int scorePct;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$scorePct%',
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
