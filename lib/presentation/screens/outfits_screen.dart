import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/garment.dart';
import '../providers/outfit_providers.dart';
import '../widgets/empty_state.dart';
import '../widgets/outfit_card.dart';

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
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: outfits.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) =>
                      OutfitCard(outfit: outfits[index]),
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
      showCheckmark: false,
      visualDensity: VisualDensity.compact,
    );
  }
}
