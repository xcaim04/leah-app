import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/garment.dart';
import '../../domain/wardrobe/garment_filter.dart';
import '../providers/providers.dart';
import '../widgets/empty_state.dart';
import '../widgets/garment_card.dart';
import '../widgets/responsive.dart';
import 'backup_screen.dart';
import 'garment_detail_screen.dart';
import 'garment_form_screen.dart';
import 'statistics_screen.dart';

class WardrobeScreen extends ConsumerStatefulWidget {
  const WardrobeScreen({super.key});

  @override
  ConsumerState<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends ConsumerState<WardrobeScreen> {
  GarmentCategory? _category;
  Occasion? _occasion;
  Season? _season;

  int get _activeCount =>
      [_category, _occasion, _season].where((f) => f != null).length;

  Future<void> _openFilters(List<Garment> items) async {
    final result = await showModalBottomSheet<_Filters>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 640),
      builder: (_) =>
          _FilterSheet(items: items, initial: (_category, _occasion, _season)),
    );
    if (result == null) return;
    setState(() {
      _category = result.$1;
      _occasion = result.$2;
      _season = result.$3;
    });
  }

  Future<void> _openForm() async {
    await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const GarmentFormScreen()));
  }

  Future<void> _openDetail(Garment garment) async {
    if (garment.id == null) return;
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => GarmentDetailScreen(garmentId: garment.id!),
      ),
    );
  }

  Future<void> _toggleFavorite(Garment garment) async {
    if (garment.id == null) return;
    await ref
        .read(garmentRepositoryProvider)
        .setFavorite(garment.id!, !garment.favorite);
    ref.invalidate(garmentsProvider);
  }

  bool _showBanner = false;

  @override
  void initState() {
    super.initState();
    _checkBackupBanner();
  }

  Future<void> _checkBackupBanner() async {
    final settings = ref.read(settingsRepositoryProvider);
    final now = DateTime.now();
    final snooze = DateTime.tryParse(
      await settings.get('backup_snooze_until') ?? '',
    );
    final last = DateTime.tryParse(await settings.get('last_backup_at') ?? '');
    final due = last == null || now.difference(last).inDays >= 30;
    final snoozed = snooze != null && snooze.isAfter(now);
    if (mounted) setState(() => _showBanner = due && !snoozed);
  }

  Future<void> _snoozeBanner() async {
    setState(() => _showBanner = false);
    await ref
        .read(settingsRepositoryProvider)
        .set(
          'backup_snooze_until',
          DateTime.now().add(const Duration(days: 7)).toIso8601String(),
        );
  }

  Future<void> _openBackup() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const BackupScreen()));
    // An export or import there may have just made the reminder obsolete.
    await _checkBackupBanner();
  }

  void _onMenu(String value) {
    switch (value) {
      case 'theme':
        showDialog<void>(
          context: context,
          builder: (_) => const _ThemeDialog(),
        );
      case 'stats':
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const StatisticsScreen()));
      case 'backup':
        _openBackup();
    }
  }

  @override
  Widget build(BuildContext context) {
    final garments = ref.watch(garmentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi armario'),
        actions: [
          IconButton(
            tooltip: 'Filtrar',
            onPressed: garments.hasValue
                ? () => _openFilters(garments.value!)
                : null,
            icon: Badge(
              isLabelVisible: _activeCount > 0,
              label: Text('$_activeCount'),
              child: const Icon(Icons.tune),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Más opciones',
            onSelected: _onMenu,
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'theme', child: Text('Tema')),
              PopupMenuItem(value: 'stats', child: Text('Estadísticas')),
              PopupMenuItem(value: 'backup', child: Text('Copia de seguridad')),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: garments.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => const EmptyState(
          icon: Icons.error_outline,
          title: 'No se pudo cargar el armario',
          message:
              'Cierra y vuelve a abrir la app. Tus prendas siguen guardadas.',
        ),
        data: (items) {
          final filtered = filterGarments(
            items,
            category: _category,
            occasion: _occasion,
            season: _season,
          );
          return ContentWidth(
            maxWidth: 1280,
            child: Column(
              children: [
                if (_showBanner && items.isNotEmpty)
                  Container(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Haz una copia de seguridad: tus datos solo están en este dispositivo.',
                          ),
                        ),
                        TextButton(
                          onPressed: _openBackup,
                          child: const Text('Hacer copia'),
                        ),
                        TextButton(
                          onPressed: _snoozeBanner,
                          child: const Text('Luego'),
                        ),
                      ],
                    ),
                  ),
                if (_activeCount > 0)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (_category != null)
                            InputChip(
                              label: Text(_category!.label),
                              onDeleted: () => setState(() => _category = null),
                            ),
                          if (_occasion != null)
                            InputChip(
                              label: Text(_occasion!.label),
                              onDeleted: () => setState(() => _occasion = null),
                            ),
                          if (_season != null)
                            InputChip(
                              label: Text(_season!.label),
                              onDeleted: () => setState(() => _season = null),
                            ),
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  child: filtered.isEmpty
                      ? EmptyState(
                          icon: Icons.checkroom_outlined,
                          title: items.isEmpty
                              ? 'Tu armario está vacío'
                              : 'Sin resultados',
                          message: items.isEmpty
                              ? 'Añade tu primera prenda para empezar.'
                              : 'Prueba con otros filtros.',
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                          // ~220px tiles: 2 columns on phones, 5–6 on desktop.
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 220,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                                childAspectRatio: 0.72,
                              ),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final garment = filtered[index];
                            return GarmentCard(
                              garment: garment,
                              onTap: () => _openDetail(garment),
                              onFavoriteToggle: () => _toggleFavorite(garment),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openForm,
        tooltip: 'Añadir prenda',
        child: const Icon(Icons.add),
      ),
    );
  }
}

typedef _Filters = (GarmentCategory?, Occasion?, Season?);

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.items, required this.initial});

  final List<Garment> items;
  final _Filters initial;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late GarmentCategory? _category = widget.initial.$1;
  late Occasion? _occasion = widget.initial.$2;
  late Season? _season = widget.initial.$3;

  Widget _group<T>(
    String title,
    List<T> values,
    String Function(T) label,
    T? selected,
    ValueChanged<T?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final v in values)
                FilterChip(
                  showCheckmark: false,
                  label: Text(label(v)),
                  selected: selected == v,
                  onSelected: (_) =>
                      setState(() => onChanged(selected == v ? null : v)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = filterGarments(
      widget.items,
      category: _category,
      occasion: _occasion,
      season: _season,
    ).length;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _group(
              'Tipo',
              GarmentCategory.values,
              (v) => v.label,
              _category,
              (v) => _category = v,
            ),
            _group(
              'Ocasión',
              Occasion.values,
              (v) => v.label,
              _occasion,
              (v) => _occasion = v,
            ),
            _group(
              'Temporada',
              Season.values,
              (v) => v.label,
              _season,
              (v) => _season = v,
            ),
            Row(
              children: [
                TextButton(
                  onPressed: () => setState(() {
                    _category = null;
                    _occasion = null;
                    _season = null;
                  }),
                  child: const Text('Limpiar'),
                ),
                const SizedBox(width: 12),
                // Expanded: the theme's minimumSize is full-width, unbounded in a Row.
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(
                      context,
                    ).pop((_category, _occasion, _season)),
                    child: Text('Ver $count prendas'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeDialog extends ConsumerWidget {
  const _ThemeDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    return AlertDialog(
      title: const Text('Tema'),
      content: RadioGroup<ThemeMode>(
        groupValue: mode,
        onChanged: (v) {
          if (v == null) return;
          ref.read(themeModeProvider.notifier).set(v);
          Navigator.of(context).pop();
        },
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: Text('Sistema'),
              value: ThemeMode.system,
            ),
            RadioListTile<ThemeMode>(
              title: Text('Claro'),
              value: ThemeMode.light,
            ),
            RadioListTile<ThemeMode>(
              title: Text('Oscuro'),
              value: ThemeMode.dark,
            ),
          ],
        ),
      ),
    );
  }
}
