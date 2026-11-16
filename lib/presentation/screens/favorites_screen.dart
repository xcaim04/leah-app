import 'package:flutter/material.dart';

import '../widgets/empty_state.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favoritos')),
      body: const EmptyState(
        icon: Icons.favorite_border,
        title: 'Aún no hay favoritos',
        message: 'Guarda los looks que más te gusten.',
      ),
    );
  }
}
