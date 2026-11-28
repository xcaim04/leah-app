import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_armario/domain/models/garment.dart';
import 'package:mi_armario/domain/models/garment_color.dart';
import 'package:mi_armario/domain/models/outfit.dart';
import 'package:mi_armario/domain/models/outfit_feedback.dart';
import 'package:mi_armario/domain/models/wear_entry.dart';
import 'package:mi_armario/presentation/providers/providers.dart';
import 'package:mi_armario/presentation/widgets/outfit_card.dart';

Garment _g(int id, GarmentCategory category) => Garment(
  id: id,
  photoPath: '$id',
  thumbPath: '$id',
  category: category,
  colors: const [GarmentColor(red: 200, green: 30, blue: 30, weight: 1)],
  occasion: Occasion.casual,
  season: Season.all,
  createdAt: DateTime(2026, 1, 1),
);

void main() {
  testWidgets('overflow menu opens with Compartir and No sugerir más', (
    tester,
  ) async {
    final outfit = Outfit(
      garments: [_g(1, GarmentCategory.top), _g(2, GarmentCategory.bottom)],
      score: 0.8,
      explanation: 'El rojo y el rojo combinan.',
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          outfitFeedbackProvider.overrideWith(
            (ref) async => const <OutfitFeedback>[],
          ),
          wearLogProvider.overrideWith((ref) async => const <WearEntry>[]),
          imageBytesProvider.overrideWith((ref, id) async => null),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: OutfitCard(outfit: outfit)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('Compartir'), findsOneWidget);
    expect(find.text('No sugerir más'), findsOneWidget);
  });
}
