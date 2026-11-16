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

  Future<void> _edit(BuildContext context) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => GarmentFormScreen(garment: garment),
      ),
    );
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de prenda'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _edit(context),
            tooltip: 'Editar',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _delete(context, ref),
            tooltip: 'Eliminar',
          ),
        ],
      ),
      body: ListView(
        children: [
          AspectRatio(
            aspectRatio: 3 / 4,
            child: Image.file(
              File(garment.photoPath),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: theme.colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.broken_image_outlined, size: 48),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(garment.category.label, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(label: Text('Ocasión: ${garment.occasion.label}')),
                    Chip(label: Text('Temporada: ${garment.season.label}')),
                    Chip(label: Text(garment.favorite ? 'Favorito' : 'No favorito')),
                  ],
                ),
                const SizedBox(height: 12),
                if (garment.colors.isNotEmpty) ...[
                  Text('Colores', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: garment.colors
                        .map(
                          (c) => Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Color.fromARGB(255, c.red, c.green, c.blue),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.colorScheme.outlineVariant,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                ],
                if (garment.notes != null && garment.notes!.isNotEmpty) ...[
                  Text('Notas', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(garment.notes!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
