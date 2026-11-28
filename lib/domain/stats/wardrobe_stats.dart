import '../color/color_math.dart';
import '../models/garment.dart';
import '../models/wear_entry.dart';
import '../outfit/harmony_rules.dart';
import '../outfit/outfit_explainer.dart';

class ColorFamily {
  const ColorFamily(this.name, this.count, this.sample);

  final String name;
  final int count;

  /// First garment of the family; its dominant colour is the swatch.
  final Garment sample;
}

class WornGarment {
  const WornGarment(this.garment, this.times);

  final Garment garment;
  final int times;
}

class UnusedGarment {
  const UnusedGarment(this.garment, this.daysSinceAdded);

  final Garment garment;
  final int daysSinceAdded;
}

class WardrobeStats {
  const WardrobeStats({
    required this.total,
    required this.categoryCounts,
    required this.colorFamilies,
    required this.mostWorn,
    required this.neverWorn,
    required this.suggestions,
  });

  final int total;
  final Map<GarmentCategory, int> categoryCounts;
  final List<ColorFamily> colorFamilies;
  final List<WornGarment> mostWorn;
  final List<UnusedGarment> neverWorn;
  final List<String> suggestions;
}

WardrobeStats computeStats(
  List<Garment> garments,
  List<WearEntry> wears,
  DateTime now,
) {
  final counts = {for (final c in GarmentCategory.values) c: 0};
  for (final g in garments) {
    counts[g.category] = counts[g.category]! + 1;
  }

  final families = <String, List<Garment>>{};
  for (final g in garments) {
    families.putIfAbsent(colorName(dominantHsl(g)), () => []).add(g);
  }
  final colorFamilies = [
    for (final e in families.entries) ColorFamily(e.key, e.value.length, e.value.first),
  ]..sort((a, b) => b.count.compareTo(a.count));

  final wornTimes = <int, int>{};
  for (final w in wears) {
    for (final id in w.garmentIds) {
      wornTimes[id] = (wornTimes[id] ?? 0) + 1;
    }
  }
  final mostWorn = [
    for (final g in garments)
      if ((wornTimes[g.id] ?? 0) > 0) WornGarment(g, wornTimes[g.id]!),
  ]..sort((a, b) => b.times.compareTo(a.times));

  final neverWorn = [
    for (final g in garments)
      if (!wornTimes.containsKey(g.id))
        UnusedGarment(g, now.difference(g.createdAt).inDays),
  ]..sort((a, b) => b.daysSinceAdded.compareTo(a.daysSinceAdded));

  final suggestions = <String>[];
  final tops = counts[GarmentCategory.top]!;
  final bottoms = counts[GarmentCategory.bottom]!;
  if (garments.isNotEmpty) {
    if (counts[GarmentCategory.footwear] == 0) {
      suggestions.add('Añade calzado para completar más looks');
    }
    if (tops > 3 * bottoms && tops > 3) {
      suggestions.add(
        'Tienes $tops partes superiores y $bottoms inferior${bottoms == 1 ? '' : 'es'}: '
        'una parte inferior más multiplica tus looks',
      );
    }
    if (counts[GarmentCategory.outerwear] == 0) {
      suggestions.add('Añade un abrigo para los días fríos y para dar capas a tus looks');
    }
    if (!garments.any((g) => isNeutral(dominantHsl(g)))) {
      suggestions.add('Añade una prenda neutra (blanco, negro, gris) para combinar con todo');
    }
    final stale = neverWorn.where((u) => u.daysSinceAdded > 60).length;
    if (stale > 0) {
      suggestions.add(
        'Tienes $stale ${stale == 1 ? 'prenda' : 'prendas'} sin estrenar desde hace más de 60 días: '
        'prueba a incluirlas en tus looks',
      );
    }
  }

  return WardrobeStats(
    total: garments.length,
    categoryCounts: counts,
    colorFamilies: colorFamilies,
    mostWorn: mostWorn.take(5).toList(),
    neverWorn: neverWorn,
    suggestions: suggestions,
  );
}
