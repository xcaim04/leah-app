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
  if (dist < 40) {
    final penalty = highSat && satDiff < 0.15 ? 0.1 : 0.0;
    return HarmonyResult(HarmonyType.analogous, 0.82 - penalty);
  }
  if (dist >= 150 && dist <= 210) {
    return const HarmonyResult(HarmonyType.complementary, 0.88);
  }
  if ((dist >= 100 && dist <= 140) || (dist >= 220 && dist <= 260)) {
    return const HarmonyResult(HarmonyType.triad, 0.8);
  }
  if (dist >= 15 && dist < 60 && highSat && satDiff < 0.2) {
    return const HarmonyResult(HarmonyType.clash, 0.25);
  }
  if (highSat && dist >= 60 && dist < 100) {
    return const HarmonyResult(HarmonyType.clash, 0.35);
  }
  return const HarmonyResult(HarmonyType.clash, 0.45);
}
