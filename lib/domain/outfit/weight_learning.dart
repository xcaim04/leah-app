import '../color/color_math.dart';
import '../models/garment.dart';
import '../models/outfit_feedback.dart';
import 'harmony_rules.dart';
import 'scoring_weights.dart';

class _FeatureStats {
  int liked = 0;
  int disliked = 0;

  void record(FeedbackRating rating) {
    if (rating == FeedbackRating.like) {
      liked++;
    } else {
      disliked++;
    }
  }
}

ScoringWeights learnWeights(
  List<OutfitFeedback> feedback,
  List<Garment> garments, {
  ScoringWeights base = const ScoringWeights.defaults(),
}) {
  if (feedback.isEmpty) return base;

  final byId = <int, Garment>{
    for (final garment in garments)
      if (garment.id != null) garment.id!: garment,
  };

  final clash = _FeatureStats();
  final similarHue = _FeatureStats();
  final neutral = _FeatureStats();
  final occasionMatch = _FeatureStats();
  final seasonMatch = _FeatureStats();

  for (final entry in feedback) {
    final resolved = <Garment>[];
    var complete = true;
    for (final id in entry.garmentIds) {
      final garment = byId[id];
      if (garment == null) {
        complete = false;
        break;
      }
      resolved.add(garment);
    }
    if (!complete || resolved.length < 2) continue;

    var hasClash = false;
    var hasSimilarHue = false;
    var hasNeutral = false;

    for (var i = 0; i < resolved.length; i++) {
      for (var j = i + 1; j < resolved.length; j++) {
        final a = dominantHsl(resolved[i]);
        final b = dominantHsl(resolved[j]);
        final result = classifyHarmony(a, b);
        if (result.type == HarmonyType.clash) hasClash = true;
        if (result.type == HarmonyType.neutral) hasNeutral = true;
        final dist = hueDistance(a.hue, b.hue);
        if (!isNeutral(a) && !isNeutral(b) && dist >= 15 && dist < 30) {
          hasSimilarHue = true;
        }
      }
    }

    if (hasClash) clash.record(entry.rating);
    if (hasSimilarHue) similarHue.record(entry.rating);
    if (hasNeutral) neutral.record(entry.rating);

    final occasion = resolved.first.occasion;
    if (resolved.every((g) => g.occasion == occasion)) {
      occasionMatch.record(entry.rating);
    }
    final seasonBase = resolved.first.season;
    if (resolved.every((g) => g.season.isCompatibleWith(seasonBase))) {
      seasonMatch.record(entry.rating);
    }
  }

  double adjustPenalty(double baseValue, _FeatureStats stats) {
    final total = stats.liked + stats.disliked;
    if (total == 0) return baseValue;
    final rate = (stats.disliked - stats.liked) / total;
    final adjusted = baseValue * (1 + 0.35 * rate);
    return _clamp(adjusted, baseValue * 0.3, baseValue * 1.7);
  }

  double adjustBonus(double baseValue, _FeatureStats stats) {
    final total = stats.liked + stats.disliked;
    if (total == 0) return baseValue;
    final rate = (stats.liked - stats.disliked) / total;
    final adjusted = baseValue * (1 + 0.35 * rate);
    return _clamp(adjusted, baseValue * 0.3, baseValue * 1.7);
  }

  // Clamp learned weights to a bounded range around their defaults to keep
  // scoring stable and explainable even with skewed or sparse feedback.
  return ScoringWeights(
    harmonyWeight: base.harmonyWeight,
    neutralBonus: adjustBonus(base.neutralBonus, neutral),
    occasionBonus: adjustBonus(base.occasionBonus, occasionMatch),
    seasonBonus: adjustBonus(base.seasonBonus, seasonMatch),
    saturationClashPenalty:
        adjustPenalty(base.saturationClashPenalty, clash),
    similarHuePenalty: adjustPenalty(base.similarHuePenalty, similarHue),
    baseScore: base.baseScore,
  );
}

double _clamp(double value, double min, double max) {
  if (min < 0) min = 0;
  if (value < min) return min;
  if (value > max) return max;
  return value;
}
