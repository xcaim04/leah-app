import '../models/garment.dart';
import 'harmony_rules.dart';

String explainOutfit(
  List<Garment> garments,
  HarmonyType harmony, {
  Occasion? occasion,
  Season? season,
}) {
  final names = garments.map((g) => _colorName(dominantHsl(g))).toList();
  final pair = _pairText(names);
  final harmonyText = switch (harmony) {
    HarmonyType.neutral => '$pair combinan con neutros que equilibran el look',
    HarmonyType.monochrome => '$pair crean una armonía monocromática elegante',
    HarmonyType.analogous => '$pair son tonos análogos suaves',
    HarmonyType.complementary => '$pair son complementarios y se realzan',
    HarmonyType.triad => '$pair aportan contraste en tríada equilibrada',
    HarmonyType.clash => '$pair contrastan fuerte; mejor ajustar tonos o saturación',
  };
  final ctx = _contextText(occasion, season);
  return ctx.isEmpty ? '$harmonyText.' : '$harmonyText; $ctx.';
}

String _pairText(List<String> names) {
  if (names.isEmpty) return 'Los tonos';
  if (names.length == 1) return 'El ${names[0]}';
  if (names.length == 2) return 'El ${names[0]} y el ${names[1]}';
  return 'El ${names[0]}, el ${names[1]} y otros tonos';
}

String _contextText(Occasion? occasion, Season? season) {
  final parts = <String>[];
  if (occasion != null) {
    parts.add('ideal para ${occasion.label.toLowerCase()}');
  }
  if (season != null) {
    final s = season == Season.midSeason
        ? 'entretiempo'
        : season.label.toLowerCase();
    parts.add('de $s');
  }
  return parts.join(' ');
}

String _colorName(HslColor color) {
  if (color.lightness < 0.12) return 'negro';
  if (color.lightness > 0.92) return 'blanco';
  if (color.saturation < 0.15) {
    if (color.lightness < 0.4) return 'gris oscuro';
    if (color.lightness > 0.7) return 'gris claro';
    return 'gris';
  }
  final h = color.hue;
  if (h < 15 || h >= 345) return 'rojo';
  if (h < 45) return 'naranja';
  if (h < 70) return 'amarillo';
  if (h < 160) return 'verde';
  if (h < 200) return 'turquesa';
  if (h < 255) return 'azul';
  if (h < 290) return 'violeta';
  if (h < 345) return 'rosa';
  return 'color';
}
