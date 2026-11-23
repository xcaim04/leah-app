import '../color/color_math.dart';
import '../models/garment.dart';
import '../models/garment_color.dart';

enum HarmonyType { neutral, monochrome, analogous, complementary, triad, clash }

class HarmonyResult {
  const HarmonyResult(this.type, this.score);

  final HarmonyType type;
  final double score;
}

GarmentColor dominantColor(Garment garment) {
  if (garment.colors.isEmpty) {
    return const GarmentColor(red: 128, green: 128, blue: 128, weight: 1);
  }
  var best = garment.colors.first;
  for (final c in garment.colors.skip(1)) {
    if (c.weight > best.weight) best = c;
  }
  return best;
}

HslColor dominantHsl(Garment garment) {
  final c = dominantColor(garment);
  return rgbToHsl(c.red, c.green, c.blue);
}

HarmonyResult classifyHarmony(HslColor a, HslColor b) {
  if (isNeutral(a) || isNeutral(b)) {
    return const HarmonyResult(HarmonyType.neutral, 0.85);
  }

  final dist = hueDistance(a.hue, b.hue);
  final satDiff = (a.saturation - b.saturation).abs();
  final highSat = a.saturation > 0.6 && b.saturation > 0.6;

  if (dist < 15) {
    return const HarmonyResult(HarmonyType.monochrome, 0.9);
  }
  final sameSatPair = highSat && satDiff < 0.2;
  // Near-identical saturated hues (15–25°) read as a mismatch, not analogous.
  // shortcut: 25° is a heuristic cutoff, retune with real garments.
  if (dist < 25 && sameSatPair) {
    return const HarmonyResult(HarmonyType.clash, 0.25);
  }
  if (dist < 40) {
    final penalty = highSat && satDiff < 0.15 ? 0.1 : 0.0;
    return HarmonyResult(HarmonyType.analogous, 0.82 - penalty);
  }
  if (dist >= 150) {
    return const HarmonyResult(HarmonyType.complementary, 0.88);
  }
  if (dist >= 100 && dist <= 140) {
    return const HarmonyResult(HarmonyType.triad, 0.8);
  }
  if (dist < 60 && sameSatPair) {
    return const HarmonyResult(HarmonyType.clash, 0.25);
  }
  if (highSat && dist >= 60 && dist < 100) {
    return const HarmonyResult(HarmonyType.clash, 0.35);
  }
  return const HarmonyResult(HarmonyType.clash, 0.45);
}

/// Per-pair harmony tallies shared by the scorer and weight learning.
class PairStats {
  double harmonySum = 0;
  int pairs = 0;
  int clash = 0;
  int neutral = 0;
  int similarHue = 0;
  final Map<HarmonyType, int> typeCounts = {};
}

PairStats pairStats(List<HslColor> colors) {
  final stats = PairStats();
  for (var i = 0; i < colors.length; i++) {
    for (var j = i + 1; j < colors.length; j++) {
      final a = colors[i];
      final b = colors[j];
      final result = classifyHarmony(a, b);
      stats.harmonySum += result.score;
      stats.pairs++;
      stats.typeCounts[result.type] = (stats.typeCounts[result.type] ?? 0) + 1;
      if (result.type == HarmonyType.clash) stats.clash++;
      if (result.type == HarmonyType.neutral) stats.neutral++;
      final dist = hueDistance(a.hue, b.hue);
      if (!isNeutral(a) && !isNeutral(b) && dist >= 15 && dist < 30) {
        stats.similarHue++;
      }
    }
  }
  return stats;
}
