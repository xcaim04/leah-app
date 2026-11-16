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
) {
  if (garments.length < 2) {
    return const OutfitScoreResult(0, HarmonyType.neutral);
  }

  var harmonySum = 0.0;
  var pairs = 0;
  var clashPairs = 0;
  var neutralPairs = 0;
  var similarHuePairs = 0;
  final typeCounts = <HarmonyType, int>{};

  for (var i = 0; i < garments.length; i++) {
    for (var j = i + 1; j < garments.length; j++) {
      final a = dominantHsl(garments[i]);
      final b = dominantHsl(garments[j]);
      final result = classifyHarmony(a, b);
      harmonySum += result.score;
      pairs++;
      typeCounts[result.type] = (typeCounts[result.type] ?? 0) + 1;
      if (result.type == HarmonyType.clash) clashPairs++;
      if (result.type == HarmonyType.neutral) neutralPairs++;
      final dist = hueDistance(a.hue, b.hue);
      if (!isNeutral(a) && !isNeutral(b) && dist >= 15 && dist < 30) {
        similarHuePairs++;
      }
    }
  }

  final avgHarmony = pairs == 0 ? 0.0 : harmonySum / pairs;
  var score = weights.baseScore + avgHarmony * weights.harmonyWeight;

  if (neutralPairs > 0) {
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

  score -= clashPairs * weights.saturationClashPenalty;
  score -= similarHuePairs * weights.similarHuePenalty;

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
  typeCounts.forEach((type, count) {
    if (count > maxCount) {
      maxCount = count;
      dominant = type;
    }
  });

  return OutfitScoreResult(score, dominant);
}

double score(List<Garment> garments, ScoringWeights weights) {
  return scoreWithDetails(garments, weights).score;
}
