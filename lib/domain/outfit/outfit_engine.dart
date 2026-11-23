import '../color/color_math.dart';
import '../models/garment.dart';
import '../models/outfit.dart';
import 'harmony_rules.dart';
import 'outfit_explainer.dart';
import 'outfit_scorer.dart';
import 'scoring_weights.dart';

List<Outfit> generate(
  List<Garment> garments, {
  Occasion? occasion,
  Season? season,
  ScoringWeights weights = const ScoringWeights.defaults(),
  int limit = 20,
  Set<String> excludedSignatures = const {},
}) {
  final filtered = garments.where((g) {
    if (occasion != null && g.occasion != occasion) return false;
    if (season != null && !g.season.isCompatibleWith(season)) return false;
    return true;
  }).toList();

  final tops = filtered
      .where((g) => g.category == GarmentCategory.top)
      .toList();
  final bottoms = filtered
      .where((g) => g.category == GarmentCategory.bottom)
      .toList();
  final dresses = filtered
      .where((g) => g.category == GarmentCategory.dress)
      .toList();
  final footwear = filtered
      .where((g) => g.category == GarmentCategory.footwear)
      .toList();
  final outerwear = filtered
      .where((g) => g.category == GarmentCategory.outerwear)
      .toList();

  final combos = <List<Garment>>[];

  for (final top in tops) {
    for (final bottom in bottoms) {
      combos.add([top, bottom]);
      for (final shoe in footwear) {
        combos.add([top, bottom, shoe]);
        for (final coat in outerwear) {
          combos.add([top, bottom, shoe, coat]);
        }
      }
      for (final coat in outerwear) {
        combos.add([top, bottom, coat]);
      }
    }
  }

  for (final dress in dresses) {
    for (final shoe in footwear) {
      combos.add([dress, shoe]);
      for (final coat in outerwear) {
        combos.add([dress, shoe, coat]);
      }
    }
    for (final coat in outerwear) {
      combos.add([dress, coat]);
    }
  }

  final hsl = Map<Garment, HslColor>.identity();
  for (final g in filtered) {
    hsl[g] = dominantHsl(g);
  }

  // Score everything, but only build explanations for the kept `limit`.
  final scored = <(Outfit, HarmonyType)>[];
  for (final items in combos) {
    final result = scoreWithHsl(items, [
      for (final g in items) hsl[g]!,
    ], weights);
    final outfit = Outfit(
      garments: items,
      score: result.score,
      explanation: '',
    );
    if (excludedSignatures.contains(outfit.signature)) continue;
    scored.add((outfit, result.dominantHarmony));
  }

  scored.sort((a, b) => b.$1.score.compareTo(a.$1.score));
  final kept = limit <= 0 || scored.length <= limit
      ? scored
      : scored.sublist(0, limit);
  return [
    for (final (o, harmony) in kept)
      Outfit(
        garments: o.garments,
        score: o.score,
        explanation: explainOutfit(
          o.garments,
          harmony,
          occasion: occasion ?? o.garments.first.occasion,
          season: season ?? o.garments.first.season,
        ),
      ),
  ];
}
