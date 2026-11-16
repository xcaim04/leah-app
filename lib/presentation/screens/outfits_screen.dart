import 'package:flutter/material.dart';

import '../widgets/empty_state.dart';

class OutfitsScreen extends StatelessWidget {
  const OutfitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Looks')),
      body: const EmptyState(
        icon: Icons.auto_awesome_outlined,
        title: 'Sin combinaciones todavía',
        message: 'El motor de looks llegará en la Fase 3.',
      ),
    );
  }
}
