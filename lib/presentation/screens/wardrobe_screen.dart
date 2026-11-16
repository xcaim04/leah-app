import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/garment.dart';
import '../providers/providers.dart';
import '../widgets/empty_state.dart';
import '../widgets/filter_bar.dart';
import '../widgets/garment_card.dart';
import 'garment_detail_screen.dart';
import 'garment_form_screen.dart';

class WardrobeScreen extends ConsumerStatefulWidget {
  const WardrobeScreen({super.key});

  @override
  ConsumerState<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends ConsumerState<WardrobeScreen> {
  GarmentCategory? _category;
  Occasion? _occasion;
  Season? _season;

  List<Garment> _applyFilters(List<Garment> items) {
    return items.where((g) {
      if (_category != null && g.category != _category) return false;
      if (_occasion != null && g.occasion != _occasion) return false;
      if (_season != null && g.season != _season) return false;
      return true;
    }).toList();
  }

  Future<void> _openForm() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const GarmentFormScreen()),
    );
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

  @override
  Widget build(BuildContext context) {
    final garments = ref.watch(garmentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mi armario')),
      body: garments.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'No se pudo cargar el armario',
          message: '$error',
        ),
        data: (items) {
          final filtered = _applyFilters(items);
          return Column(
            children: [
              FilterBar(
                selectedCategory: _category,
                selectedOccasion: _occasion,
                selectedSeason: _season,
                onCategoryChanged: (v) => setState(() => _category = v),
                onOccasionChanged: (v) => setState(() => _occasion = v),
                onSeasonChanged: (v) => setState(() => _season = v),
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
                        padding: const EdgeInsets.all(12),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
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
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openForm,
        child: const Icon(Icons.add),
      ),
    );
  }
}
