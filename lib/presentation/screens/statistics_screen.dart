import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/garment.dart';
import '../../domain/outfit/harmony_rules.dart';
import '../../domain/stats/wardrobe_stats.dart';
import '../providers/providers.dart';
import '../widgets/garment_image.dart';
import '../widgets/responsive.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final garments = ref.watch(garmentsProvider);
    final wears = ref.watch(wearLogProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Estadísticas')),
      body: garments.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text('No se pudieron cargar las prendas: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Añade prendas a tu armario para ver tus estadísticas.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final stats = computeStats(
            list,
            wears.valueOrNull ?? const [],
            DateTime.now(),
          );
          final summary = _Section('Resumen', child: _Summary(stats));
          final colors = _Section(
            'Colores',
            child: _Colors(stats.colorFamilies),
          );
          final mostWorn = stats.mostWorn.isEmpty
              ? null
              : _Section(
                  'Más usadas',
                  child: _Thumbs([
                    for (final m in stats.mostWorn)
                      (
                        m.garment,
                        '${m.times} ${m.times == 1 ? 'vez' : 'veces'}',
                      ),
                  ]),
                );
          final unused = stats.neverWorn.isEmpty
              ? null
              : _Section(
                  'Sin usar',
                  child: _Thumbs([
                    for (final u in stats.neverWorn.take(10))
                      (u.garment, '${u.daysSinceAdded} d'),
                  ]),
                );
          final tips = stats.suggestions.isEmpty
              ? null
              : _Section('Sugerencias', child: _Suggestions(stats.suggestions));
          final left = [summary, ?tips];
          final right = [colors, ?mostWorn, ?unused];
          return ContentWidth(
            maxWidth: 1100,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: Breakpoints.isExpanded(context)
                  ? [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: Column(children: left)),
                          const SizedBox(width: 16),
                          Expanded(child: Column(children: right)),
                        ],
                      ),
                    ]
                  : [summary, colors, ?mostWorn, ?unused, ?tips],
            ),
          );
        },
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title, {required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary(this.stats);

  final WardrobeStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final max = stats.categoryCounts.values.fold<int>(
      1,
      (a, b) => b > a ? b : a,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${stats.total} ${stats.total == 1 ? 'prenda' : 'prendas'}',
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        for (final e in stats.categoryCounts.entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(e.key.label, overflow: TextOverflow.ellipsis),
                ),
                Expanded(
                  flex: 5,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: e.value / max,
                      minHeight: 8,
                    ),
                  ),
                ),
                SizedBox(
                  width: 28,
                  child: Text('${e.value}', textAlign: TextAlign.end),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Colors extends StatelessWidget {
  const _Colors(this.families);

  final List<ColorFamily> families;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final f in families)
          Builder(
            builder: (_) {
              final c = dominantColor(f.sample);
              return Chip(
                avatar: CircleAvatar(
                  backgroundColor: Color.fromARGB(255, c.red, c.green, c.blue),
                  radius: 10,
                ),
                label: Text('${f.name} · ${f.count}'),
                side: BorderSide(color: scheme.outlineVariant),
              );
            },
          ),
      ],
    );
  }
}

class _Thumbs extends StatelessWidget {
  const _Thumbs(this.items);

  final List<(Garment, String)> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final (g, label) in items)
          SizedBox(
            width: 64,
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: GarmentImage(imageId: g.thumbPath, cacheWidth: 160),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: theme.textTheme.labelSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Suggestions extends StatelessWidget {
  const _Suggestions(this.items);

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final s in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(s)),
              ],
            ),
          ),
      ],
    );
  }
}
