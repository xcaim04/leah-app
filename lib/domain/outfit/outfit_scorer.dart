import '../color/color_math.dart';
import '../models/garment.dart';
import 'harmony_rules.dart';
import 'scoring_weights.dart';

class OutfitScoreResult {
  const OutfitScoreResult(this.score, this.dominantHarmony);

  final double score;
  final HarmonyType dominantHarmony;
}

OutfitScoreResult scoreWithDetails(
  List<Garment> garments,
  ScoringWeights weights,
) => scoreWithHsl(garments, garments.map(dominantHsl).toList(), weights);

/// Same as [scoreWithDetails] with each garment's [dominantHsl] precomputed
/// (parallel to [garments]), so `generate` doesn't redo it per combination.
OutfitScoreResult scoreWithHsl(
  List<Garment> garments,
  List<HslColor> hsl,
  ScoringWeights weights,
) {
  if (garments.length < 2) {
    return const OutfitScoreResult(0, HarmonyType.neutral);
  }

  final stats = pairStats(hsl);

  final avgHarmony = stats.pairs == 0 ? 0.0 : stats.harmonySum / stats.pairs;
  var score = weights.baseScore + avgHarmony * weights.harmonyWeight;

  if (stats.neutral > 0) {
    score += weights.neutralBonus;
  }

  final occasion = garments.first.occasion;
  if (garments.every((g) => g.occasion == occasion)) {
    score += weights.occasionBonus;
  }

  final seasonBase = garments.first.season;
  if (garments.every((g) => g.season.isCompatibleWith(seasonBase))) {
    score += weights.seasonBonus;
  }

  score -= stats.clash * weights.saturationClashPenalty;
  score -= stats.similarHue * weights.similarHuePenalty;

  // Divide by the best achievable score (0.9 = top pair harmony) instead of
  // clamping, otherwise most looks saturate at 100% and tie.
  final maxScore = weights.baseScore +
      0.9 * weights.harmonyWeight +
      weights.neutralBonus +
      weights.occasionBonus +
      weights.seasonBonus;
  score = (score / maxScore).clamp(0.0, 1.0);

  var dominant = HarmonyType.neutral;
  var maxCount = -1;
  stats.typeCounts.forEach((type, count) {
    if (count > maxCount) {
      maxCount = count;
      dominant = type;
    }
  });

  return OutfitScoreResult(score, dominant);
}
