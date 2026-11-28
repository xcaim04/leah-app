import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/outfit_providers.dart';
import '../widgets/empty_state.dart';
import '../widgets/outfit_card.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outfitsAsync = ref.watch(likedOutfitsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Favoritos')),
      body: outfitsAsync.when(
        data: (liked) {
          if (liked.isEmpty) {
            return const _Narrow(
              child: EmptyState(
                icon: Icons.favorite_border,
                title: 'Aún no hay favoritos',
                message: 'Marca con "me gusta" los looks que más te gusten.',
              ),
            );
          }
          return CustomScrollView(slivers: [SliverOutfitGrid(outfits: liked)]);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const _Narrow(
          child: EmptyState(
            icon: Icons.error_outline,
            title: 'No se pudieron cargar los favoritos',
            message: 'Vuelve a intentarlo en un momento.',
          ),
        ),
      ),
    );
  }
}

/// Centers a state message and keeps it from stretching on wide windows.
class _Narrow extends StatelessWidget {
  const _Narrow({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: child,
    ),
  );
}
