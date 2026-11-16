import '../models/garment.dart';
import '../models/outfit.dart';
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
    combos.add([dress]);
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

  final outfits = combos
      .map((items) {
        final result = scoreWithDetails(items, weights);
        final explanation = explainOutfit(
          items,
          result.dominantHarmony,
          occasion: occasion ?? items.first.occasion,
          season: season ?? items.first.season,
        );
        return Outfit(
          garments: items,
          score: result.score,
          explanation: explanation,
        );
      })
      .where((o) => !excludedSignatures.contains(o.signature))
      .toList();

  outfits.sort((a, b) => b.score.compareTo(a.score));
  if (limit <= 0 || outfits.length <= limit) return outfits;
  return outfits.sublist(0, limit);
}
