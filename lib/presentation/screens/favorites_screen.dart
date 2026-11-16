import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/outfit_feedback.dart';
import '../providers/outfit_providers.dart';
import '../widgets/empty_state.dart';
import '../widgets/outfit_card.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outfitsAsync = ref.watch(generatedOutfitsProvider);
    final ratings = ref.watch(latestRatingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Favoritos')),
      body: outfitsAsync.when(
        data: (outfits) {
          final liked = outfits
              .where((o) => ratings[o.signature] == FeedbackRating.like)
              .toList();
          if (liked.isEmpty) {
            return const EmptyState(
              icon: Icons.favorite_border,
              title: 'Aún no hay favoritos',
              message: 'Marca con "me gusta" los looks que más te gusten.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            itemCount: liked.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) => OutfitCard(outfit: liked[index]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error al cargar favoritos: $e')),
      ),
    );
  }
}
