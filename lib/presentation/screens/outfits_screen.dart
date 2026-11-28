import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/garment.dart';
import '../providers/outfit_providers.dart';
import '../widgets/empty_state.dart';
import '../widgets/look_of_the_day_section.dart';
import '../widgets/outfit_card.dart';
import '../widgets/responsive.dart';

class OutfitsScreen extends ConsumerWidget {
  const OutfitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(outfitFiltersProvider);
    final outfitsAsync = ref.watch(generatedOutfitsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Looks')),
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: ContentWidth(maxWidth: 1280, child: LookOfTheDaySection()),
          ),
          SliverToBoxAdapter(child: _FiltersBar(filters: filters)),
          ...outfitsAsync.when(
            data: (outfits) {
              if (outfits.isEmpty) {
                return const [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.auto_awesome_outlined,
                      title: 'Sin combinaciones',
                      message:
                          'Añade más prendas o ajusta los filtros para generar looks.',
                    ),
                  ),
                ];
              }
              return [SliverOutfitGrid(outfits: outfits)];
            },
            loading: () => const [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
            error: (_, __) => const [
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.error_outline,
                  title: 'No se pudieron generar los looks',
                  message: 'Vuelve a intentarlo en un momento.',
                ),
              ),
            ],
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
        child: ContentWidth(
          maxWidth: 1280,
          child: Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Row(
                children: [
                  Expanded(
                    child: _FilterDropdown<Occasion>(
                      title: 'Ocasión',
                      values: Occasion.values,
                      selected: filters.occasion,
                      labelOf: (o) => o.label,
                      onSelected: notifier.setOccasion,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _FilterDropdown<Season>(
                      title: 'Temporada',
                      values: Season.values,
                      selected: filters.season,
                      labelOf: (s) => s.label,
                      onSelected: notifier.setSeason,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  const _FilterDropdown({
    required this.title,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
  });

  final String title;
  final List<T> values;
  final T? selected;
  final String Function(T) labelOf;
  final ValueChanged<T?> onSelected;

  @override
  Widget build(BuildContext context) {
    final check = const Icon(Icons.check);
    MenuItemButton item(String label, T? value) => MenuItemButton(
      leadingIcon: selected == value ? check : const SizedBox(width: 24),
      onPressed: () => onSelected(value),
      child: Text(label),
    );

    return MenuAnchor(
      menuChildren: [
        item('Todas', null),
        for (final v in values) item(labelOf(v), v),
      ],
      builder: (context, controller, _) => OutlinedButton(
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
        child: Row(
          children: [
            Expanded(
              child: Text(
                // Bare title when unfiltered: "Temporada: Todas" doesn't fit on phones.
                selected == null ? title : labelOf(selected as T),
                semanticsLabel:
                    '$title: ${selected == null ? 'Todas' : labelOf(selected as T)}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.expand_more),
          ],
        ),
      ),
    );
  }
}
