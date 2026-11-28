import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/garment.dart';
import '../../domain/models/wear_entry.dart';
import '../providers/outfit_providers.dart';
import '../providers/providers.dart';
import '../widgets/empty_state.dart';
import '../widgets/garment_image.dart';
import '../widgets/responsive.dart';

const _monthNames = [
  'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', //
  'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
];
const _weekdayInitials = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

/// "Diario": calendar of the looks she logged with "Me lo puse hoy".
class DiaryScreen extends ConsumerStatefulWidget {
  const DiaryScreen({super.key});

  @override
  ConsumerState<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends ConsumerState<DiaryScreen> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  void _shift(int months) =>
      setState(() => _month = DateTime(_month.year, _month.month + months));

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(wearLogProvider);
    final garments = {
      for (final g in ref.watch(garmentsProvider).asData?.value ?? <Garment>[])
        g.id: g,
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Diario')),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const EmptyState(
          icon: Icons.error_outline,
          title: 'No se pudo cargar el diario',
        ),
        data: (entries) {
          if (entries.isEmpty) {
            return const EmptyState(
              icon: Icons.calendar_month_outlined,
              title: 'Aún no has registrado looks',
              message: 'Pulsa «Me lo puse hoy» en un look para guardarlo aquí.',
            );
          }
          final byDay = <String, List<WearEntry>>{};
          for (final e in entries) {
            (byDay[WearEntry.dayKey(e.wornOn)] ??= []).add(e);
          }
          return ContentWidth(
            maxWidth: 760,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _MonthHeader(month: _month, onShift: _shift),
                _MonthGrid(
                  month: _month,
                  byDay: byDay,
                  garments: garments,
                  onDayTap: (day) => showModalBottomSheet<void>(
                    context: context,
                    showDragHandle: true,
                    constraints: const BoxConstraints(maxWidth: 640),
                    builder: (context) => _DaySheet(day: day),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({required this.month, required this.onShift});

  final DateTime month;
  final ValueChanged<int> onShift;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: 'Mes anterior',
          icon: const Icon(Icons.chevron_left),
          onPressed: () => onShift(-1),
        ),
        Expanded(
          child: Text(
            '${_monthNames[month.month - 1]} ${month.year}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        IconButton(
          tooltip: 'Mes siguiente',
          icon: const Icon(Icons.chevron_right),
          onPressed: () => onShift(1),
        ),
      ],
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.byDay,
    required this.garments,
    required this.onDayTap,
  });

  final DateTime month;
  final Map<String, List<WearEntry>> byDay;
  final Map<int?, Garment> garments;
  final ValueChanged<DateTime> onDayTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final now = DateTime.now();
    final todayKey = WearEntry.dayKey(now);
    final leading = month.weekday - 1; // Monday first.
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      // Wider windows get squarer cells so the grid doesn't grow too tall.
      childAspectRatio: MediaQuery.sizeOf(context).width >= Breakpoints.medium
          ? 1
          : 0.75,
      children: [
        for (final d in _weekdayInitials)
          Center(
            child: Text(
              d,
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        for (var i = 0; i < leading; i++) const SizedBox.shrink(),
        for (var day = 1; day <= daysInMonth; day++)
          Builder(
            builder: (context) {
              final date = DateTime(month.year, month.month, day);
              final key = WearEntry.dayKey(date);
              final entries = byDay[key];
              final first = entries == null
                  ? null
                  : garments[entries.first.garmentIds.firstOrNull];
              final isToday = key == todayKey;
              return Semantics(
                button: entries != null,
                label:
                    '$day ${_monthNames[month.month - 1]}'
                    '${entries == null ? '' : ', ${entries.length} looks'}',
                excludeSemantics: true,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: entries == null ? null : () => onDayTap(date),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: isToday ? scheme.primaryContainer : null,
                    ),
                    padding: const EdgeInsets.all(2),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (entries != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: first == null
                                ? ColoredBox(color: scheme.secondaryContainer)
                                : GarmentImage(
                                    imageId: first.thumbPath,
                                    cacheWidth: 120,
                                  ),
                          ),
                        Align(
                          alignment: Alignment.topLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: entries != null
                                  ? scheme.surface.withValues(alpha: 0.85)
                                  : null,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$day',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: isToday && entries == null
                                    ? scheme.onPrimaryContainer
                                    : scheme.onSurface,
                                fontWeight: isToday ? FontWeight.bold : null,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

/// Looks logged on [day]; watches the log so deletions update the sheet.
class _DaySheet extends ConsumerWidget {
  const _DaySheet({required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = WearEntry.dayKey(day);
    final entries = [
      for (final e in ref.watch(wearLogProvider).asData?.value ?? <WearEntry>[])
        if (WearEntry.dayKey(e.wornOn) == key) e,
    ];
    final garments = {
      for (final g in ref.watch(garmentsProvider).asData?.value ?? <Garment>[])
        g.id: g,
    };
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(
            '${day.day} de ${_monthNames[day.month - 1].toLowerCase()}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (entries.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('No hay looks registrados este día.'),
            ),
          for (final entry in entries)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 72,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          for (final id in entry.garmentIds)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: SizedBox(
                                  width: 54,
                                  child: garments[id] == null
                                      ? ColoredBox(
                                          color: scheme.surfaceContainer,
                                        )
                                      : GarmentImage(
                                          imageId: garments[id]!.thumbPath,
                                          cacheWidth: 160,
                                        ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Eliminar del diario',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () =>
                        ref.read(wearLogControllerProvider).delete(entry.id!),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
