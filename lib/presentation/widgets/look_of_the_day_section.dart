import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/today/cuban_holidays.dart';
import '../../domain/today/look_of_the_day.dart';
import '../providers/outfit_providers.dart';
import 'outfit_card.dart';

/// "Look del día": swipeable suggestions for today's weather and day type.
class LookOfTheDaySection extends ConsumerStatefulWidget {
  const LookOfTheDaySection({super.key});

  @override
  ConsumerState<LookOfTheDaySection> createState() =>
      _LookOfTheDaySectionState();
}

class _LookOfTheDaySectionState extends ConsumerState<LookOfTheDaySection> {
  final _controller = PageController(viewportFraction: 0.92);
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final looks = ref.watch(lookOfTheDayProvider).asData?.value;
    final count = looks?.length ?? 0;
    final page = count == 0 ? 0 : _page.clamp(0, count - 1);

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      'Look del día',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                if (count > 1)
                  Semantics(
                    label: 'Sugerencia ${page + 1} de $count',
                    excludeSemantics: true,
                    child: Text(
                      '${page + 1} / $count',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
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
            Semantics(
              label: count > 1
                  ? 'Sugerencias de hoy. Desliza para ver más.'
                  : 'Sugerencia de hoy',
              child: SizedBox(
                // shortcut: fixed height, long explanations scroll inside
                // the card; measure pages if cards grow much taller.
                height: 250,
                child: PageView.builder(
                  controller: _controller,
                  itemCount: count,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    child: SingleChildScrollView(
                      child: OutfitCard(outfit: looks[i]),
                    ),
                  ),
                ),
              ),
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
