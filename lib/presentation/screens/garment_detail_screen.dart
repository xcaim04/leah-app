import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/garment.dart';
import '../providers/providers.dart';
import 'garment_form_screen.dart';

class GarmentDetailScreen extends ConsumerWidget {
  const GarmentDetailScreen({super.key, required this.garmentId});

  final int garmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final garmentsAsync = ref.watch(garmentsProvider);
    return garmentsAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $error')),
      ),
      data: (items) {
        Garment? garment;
        for (final item in items) {
          if (item.id == garmentId) {
            garment = item;
            break;
          }
        }
        if (garment == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Prenda no encontrada')),
          );
        }
        return _GarmentDetailBody(garment: garment);
      },
    );
  }
}

class _GarmentDetailBody extends ConsumerWidget {
  const _GarmentDetailBody({required this.garment});

  final Garment garment;

  static const _months = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];

  Future<void> _edit(BuildContext context) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => GarmentFormScreen(garment: garment),
      ),
    );
  }

  Future<void> _toggleFavorite(BuildContext context, WidgetRef ref) async {
    final id = garment.id;
    if (id == null) return;
    await ref.read(garmentRepositoryProvider).setFavorite(id, !garment.favorite);
    ref.invalidate(garmentsProvider);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar prenda'),
        content: const Text('¿Seguro que quieres eliminar esta prenda?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final id = garment.id;
    if (id == null) return;
    try {
      final repository = ref.read(garmentRepositoryProvider);
      final imageStorage = ref.read(imageStorageProvider);
      final removed = await repository.deleteById(id);
      if (removed != null) {
        await imageStorage.delete(removed.photoPath, removed.thumbPath);
      }
      ref.invalidate(garmentsProvider);
      if (context.mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo eliminar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final created = garment.createdAt;
    final addedLabel =
        'Añadido el ${created.day} de ${_months[created.month - 1]}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de prenda'),
        actions: [
          IconButton(
            icon: Icon(
              garment.favorite ? Icons.favorite : Icons.favorite_border,
              color: garment.favorite ? scheme.primary : null,
            ),
            tooltip: garment.favorite
                ? 'Quitar de favoritos'
                : 'Marcar como favorito',
            onPressed: () => _toggleFavorite(context, ref),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: AspectRatio(
                aspectRatio: 4 / 5,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(
                      File(garment.photoPath),
                      fit: BoxFit.cover,
                      cacheWidth: 1200,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: scheme.surfaceContainerHighest,
                        child: const Icon(Icons.broken_image_outlined, size: 48),
                      ),
                    ),
                    Positioned(
                      left: 14,
                      top: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: scheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          garment.category.label.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 0.6,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(garment.category.label,
                    style: theme.textTheme.headlineLarge),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 14, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text(addedLabel, style: theme.textTheme.bodySmall),
                  ],
                ),
                if (garment.colors.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    'PALETA EXTRAÍDA',
                    style: theme.textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.1,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: garment.colors
                        .map(
                          (c) => Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: Color.fromARGB(255, c.red, c.green, c.blue),
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: scheme.outlineVariant),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _SpecCard(
                        icon: Icons.celebration_outlined,
                        iconBg: scheme.primaryFixed,
                        iconColor: scheme.primary,
                        label: 'Ocasión',
                        value: garment.occasion.label,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SpecCard(
                        icon: Icons.calendar_today_outlined,
                        iconBg: scheme.secondaryContainer,
                        iconColor: scheme.onSecondaryContainer,
                        label: 'Temporada',
                        value: garment.season.label,
                      ),
                    ),
                  ],
                ),
                if (garment.notes != null && garment.notes!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: scheme.primary.withValues(alpha: 0.05),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.edit_note,
                                size: 20, color: scheme.primary),
                            const SizedBox(width: 8),
                            Text('Detalles y cuidados',
                                style: theme.textTheme.labelLarge),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          garment.notes!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Material(
                color: scheme.surfaceContainerHigh,
                shape: const CircleBorder(),
                child: IconButton(
                  onPressed: () => _delete(context, ref),
                  tooltip: 'Eliminar prenda',
                  icon: Icon(Icons.delete_outline, color: scheme.tertiary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _edit(context),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar prenda'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpecCard extends StatelessWidget {
  const _SpecCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(height: 10),
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 0.8,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(value, style: theme.textTheme.labelLarge),
        ],
      ),
    );
  }
}
