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
  Set<int> recentlyWorn = const {},
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
  final accessories = filtered
      .where((g) => g.category == GarmentCategory.accessory)
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
  (double, HarmonyType) score(List<Garment> items) {
    final result = scoreWithHsl(items, [
      for (final g in items) hsl[g]!,
    ], weights);
    final worn = items.where((g) => recentlyWorn.contains(g.id)).length;
    final penalized = (result.score - worn * recentlyWornPenalty).clamp(
      0.0,
      1.0,
    );
    return (penalized, result.dominantHarmony);
  }

  final scored = <(Outfit, HarmonyType)>[];
  for (final items in combos) {
    final (value, harmony) = score(items);
    final outfit = Outfit(garments: items, score: value, explanation: '');
    if (excludedSignatures.contains(outfit.signature)) continue;
    scored.add((outfit, harmony));
  }

  scored.sort((a, b) => b.$1.score.compareTo(a.$1.score));
  final kept = limit <= 0 || scored.length <= limit
      ? scored
      : scored.sublist(0, limit);

  // Finish each kept look with the accessory that most improves it, if any.
  final finished = [
    for (final entry in kept)
      if (accessories.isEmpty)
        entry
      else
        _accessorize(entry, accessories, score, excludedSignatures),
  ]..sort((a, b) => b.$1.score.compareTo(a.$1.score));

  return [
    for (final (o, harmony) in finished)
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

/// Score lost per garment worn in the last few days, so suggestions rotate.
const double recentlyWornPenalty = 0.06;

(Outfit, HarmonyType) _accessorize(
  (Outfit, HarmonyType) entry,
  List<Garment> accessories,
  (double, HarmonyType) Function(List<Garment>) score,
  Set<String> excludedSignatures,
) {
  var best = entry;
  for (final accessory in accessories) {
    final items = [...entry.$1.garments, accessory];
    final (value, harmony) = score(items);
    if (value <= best.$1.score) continue;
    final outfit = Outfit(garments: items, score: value, explanation: '');
    if (excludedSignatures.contains(outfit.signature)) continue;
    best = (outfit, harmony);
  }
  return best;
}
