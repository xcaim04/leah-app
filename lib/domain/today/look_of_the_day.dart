import '../models/garment.dart';
import '../models/outfit.dart';
import '../outfit/outfit_engine.dart' as engine;
import '../outfit/scoring_weights.dart';
import 'cuban_holidays.dart';

/// Current weather as reported by the weather service.
class Weather {
  const Weather({required this.temperatureC, required this.weatherCode});

  final double temperatureC;

  /// WMO weather interpretation code (Open-Meteo `weather_code`).
  final int weatherCode;

  Season get season => seasonForTemperature(temperatureC);
  bool get isRainy => isRainCode(weatherCode);
  String get label => weatherCodeLabel(weatherCode);
}

/// ≥ 24 °C summer, 15–24 °C mid-season, < 15 °C winter.
Season seasonForTemperature(double celsius) {
  if (celsius >= 24) return Season.summer;
  if (celsius >= 15) return Season.midSeason;
  return Season.winter;
}

/// Drizzle, rain, showers and thunderstorms.
bool isRainCode(int code) =>
    (code >= 51 && code <= 67) ||
    (code >= 80 && code <= 82) ||
    (code >= 95 && code <= 99);

String weatherCodeLabel(int code) {
  if (code == 0) return 'Soleado';
  if (code <= 2) return 'Parcialmente nublado';
  if (code == 3) return 'Nublado';
  if (code == 45 || code == 48) return 'Niebla';
  if (code >= 51 && code <= 57) return 'Llovizna';
  if (code >= 61 && code <= 67) return 'Lluvia';
  if (code >= 71 && code <= 77) return 'Nieve';
  if (code >= 80 && code <= 82) return 'Chubascos';
  if (code == 85 || code == 86) return 'Nieve';
  if (code >= 95 && code <= 99) return 'Tormenta';
  return 'Variable';
}

enum DayType { holiday, weekend, weekday }

DayType dayTypeFor(DateTime date) {
  if (cubanHolidayName(date) != null) return DayType.holiday;
  if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) {
    return DayType.weekend;
  }
  return DayType.weekday;
}

Occasion preferredOccasion(DayType type) => switch (type) {
  DayType.holiday => Occasion.party,
  DayType.weekend => Occasion.casual,
  DayType.weekday => Occasion.work,
};

/// Bonus for looks with outerwear on rainy days; small enough to only
/// reorder looks that already score close to each other.
const double rainOuterwearBonus = 0.05;

/// Today's suggestions: prefers the day's occasion but falls back to any
/// occasion so she always gets looks when the wardrobe allows it.
/// [weather] null means unknown, treated as warm (Cuba).
List<Outfit> lookOfTheDay(
  List<Garment> garments, {
  required DateTime date,
  Weather? weather,
  ScoringWeights weights = const ScoringWeights.defaults(),
  Set<String> excludedSignatures = const {},
  int limit = 10,
}) {
  final season = weather?.season ?? Season.summer;
  List<Outfit> run(Occasion? occasion) => engine.generate(
    garments,
    occasion: occasion,
    season: season,
    weights: weights,
    limit: limit * 2,
    excludedSignatures: excludedSignatures,
  );

  var outfits = run(preferredOccasion(dayTypeFor(date)));
  if (outfits.isEmpty) outfits = run(null);

  if (weather?.isRainy ?? false) {
    double nudged(Outfit o) =>
        o.score +
        (o.garments.any((g) => g.category == GarmentCategory.outerwear)
            ? rainOuterwearBonus
            : 0);
    final indexed = outfits.indexed.toList()
      ..sort((a, b) {
        final byScore = nudged(b.$2).compareTo(nudged(a.$2));
        return byScore != 0 ? byScore : a.$1.compareTo(b.$1);
      });
    outfits = [for (final e in indexed) e.$2];
  }
  return outfits.length <= limit ? outfits : outfits.sublist(0, limit);
}
