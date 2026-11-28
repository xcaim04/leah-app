import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/today/cuban_holidays.dart';
import '../../domain/today/look_of_the_day.dart';
import '../providers/outfit_providers.dart';
import 'outfit_card.dart';
import 'responsive.dart';

/// "Look del día": suggestions for today's weather and day type.
class LookOfTheDaySection extends ConsumerStatefulWidget {
  const LookOfTheDaySection({super.key});

  @override
  ConsumerState<LookOfTheDaySection> createState() =>
      _LookOfTheDaySectionState();
}

class _LookOfTheDaySectionState extends ConsumerState<LookOfTheDaySection> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final looks = ref.watch(lookOfTheDayProvider).asData?.value;
    final count = looks?.length ?? 0;
    final index = count == 0 ? 0 : _index.clamp(0, count - 1);

    final title = Semantics(
      header: true,
      child: Text(
        'Look del día',
        style: theme.textTheme.titleLarge?.copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    final counter = count > 1
        ? Semantics(
            label: 'Sugerencia ${index + 1} de $count',
            excludeSemantics: true,
            child: Text(
              '${index + 1} / $count',
              style: theme.textTheme.labelLarge?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          )
        : null;
    final another = count > 1
        ? TextButton.icon(
            onPressed: () => setState(() => _index = (index + 1) % count),
            icon: const Icon(Icons.refresh),
            label: const Text('Otra sugerencia'),
          )
        : null;
    final card = AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: looks == null || looks.isEmpty
          ? null
          : OutfitCard(
              key: ValueKey(looks[index].signature),
              outfit: looks[index],
              showScore: true,
            ),
    );
    final wide = Breakpoints.isExpanded(context);

    if (wide && looks != null && looks.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              flex: 0,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: card,
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title,
                    const SizedBox(height: 8),
                    const _TodayHeader(),
                    if (counter != null) ...[
                      const SizedBox(height: 12),
                      counter,
                    ],
                    if (another != null) ...[
                      const SizedBox(height: 4),
                      another,
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(child: title),
                if (counter != null) counter,
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 10),
            child: _TodayHeader(),
          ),
          if (looks == null)
            const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (looks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Añade más prendas para recibir tu look del día.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(children: [card, if (another != null) another]),
            ),
        ],
      ),
    );
  }
}

class _TodayHeader extends ConsumerWidget {
  const _TodayHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(todayWeatherProvider);
    final weather = weatherAsync.asData?.value;
    final today = DateTime.now();
    final holiday = cubanHolidayName(today);

    final String weatherText;
    final IconData weatherIcon;
    if (weatherAsync.isLoading) {
      weatherText = 'Consultando el clima…';
      weatherIcon = Icons.cloud_sync_outlined;
    } else if (weather == null) {
      weatherText = 'Clima cálido (sin ubicación)';
      weatherIcon = Icons.wb_sunny_outlined;
    } else {
      weatherText =
          '${weather.temperatureC.round()} °C · ${weather.label}'
          '${weather.isRainy ? ' · lleva abrigo' : ''}';
      weatherIcon = _iconFor(weather);
    }

    final dayText = holiday != null
        ? 'Hoy es feriado: $holiday'
        : switch (dayTypeFor(today)) {
            DayType.weekend => 'Fin de semana: looks casuales',
            _ => 'Día laborable: looks de trabajo',
          };

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        _InfoPill(icon: weatherIcon, text: weatherText),
        _InfoPill(
          icon: holiday != null ? Icons.celebration_outlined : Icons.event,
          text: dayText,
        ),
      ],
    );
  }

  static IconData _iconFor(Weather w) {
    if (w.weatherCode >= 95) return Icons.thunderstorm_outlined;
    if (w.isRainy) return Icons.umbrella_outlined;
    if (w.weatherCode == 0) return Icons.wb_sunny_outlined;
    if (w.weatherCode <= 3) return Icons.wb_cloudy_outlined;
    if (w.weatherCode == 45 || w.weatherCode == 48) return Icons.foggy;
    return Icons.ac_unit;
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      label: text,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: scheme.secondaryContainer,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: scheme.onSecondaryContainer),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                text,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.onSecondaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
