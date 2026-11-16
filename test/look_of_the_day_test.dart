import 'package:flutter_test/flutter_test.dart';
import 'package:mi_armario/domain/models/garment.dart';
import 'package:mi_armario/domain/today/cuban_holidays.dart';
import 'package:mi_armario/domain/today/look_of_the_day.dart';

import 'outfit_engine_test.dart' show g, blue, white, red;

void main() {
  group('Cuban holidays', () {
    test('Good Friday for known years', () {
      expect(cubanHolidayName(DateTime(2025, 4, 18)), 'Viernes Santo');
      expect(cubanHolidayName(DateTime(2026, 4, 3)), 'Viernes Santo');
      expect(cubanHolidayName(DateTime(2027, 3, 26)), 'Viernes Santo');
      expect(easterSunday(2024), DateTime(2024, 3, 31));
      expect(cubanHolidayName(DateTime(2026, 4, 5)), isNull);
    });

    test('fixed holidays', () {
      for (final (m, d) in [
        (1, 1), (1, 2), (5, 1), (7, 25), (7, 26), (7, 27), //
        (10, 10), (12, 25), (12, 31),
      ]) {
        expect(
          cubanHolidayName(DateTime(2026, m, d)),
          isNotNull,
          reason: '$m/$d',
        );
      }
      expect(cubanHolidayName(DateTime(2026, 5, 1)), 'Día de los Trabajadores');
      expect(cubanHolidayName(DateTime(2026, 11, 16)), isNull);
    });

    test('day type and occasion', () {
      expect(dayTypeFor(DateTime(2026, 5, 1)), DayType.holiday);
      expect(dayTypeFor(DateTime(2026, 11, 14)), DayType.weekend); // Saturday
      expect(dayTypeFor(DateTime(2026, 11, 16)), DayType.weekday); // Monday
      expect(preferredOccasion(DayType.holiday), Occasion.party);
      expect(preferredOccasion(DayType.weekend), Occasion.casual);
      expect(preferredOccasion(DayType.weekday), Occasion.work);
    });
  });

  group('weather', () {
    test('temperature thresholds', () {
      expect(seasonForTemperature(30), Season.summer);
      expect(seasonForTemperature(24), Season.summer);
      expect(seasonForTemperature(23.9), Season.midSeason);
      expect(seasonForTemperature(15), Season.midSeason);
      expect(seasonForTemperature(14.9), Season.winter);
    });

    test('rain codes', () {
      for (final c in [51, 61, 67, 80, 82, 95, 99]) {
        expect(isRainCode(c), isTrue, reason: '$c');
      }
      for (final c in [0, 3, 45, 50, 68, 71, 79, 83, 94]) {
        expect(isRainCode(c), isFalse, reason: '$c');
      }
    });
  });

  group('lookOfTheDay', () {
    final monday = DateTime(2026, 11, 16);

    test('prefers the day occasion, falls back to any occasion', () {
      final casualOnly = [
        g(id: 1, category: GarmentCategory.top, color: blue),
        g(id: 2, category: GarmentCategory.bottom, color: white),
      ];
      expect(lookOfTheDay(casualOnly, date: monday), isNotEmpty);

      final mixed = [
        ...casualOnly,
        g(
          id: 3,
          category: GarmentCategory.top,
          color: red,
          occasion: Occasion.work,
        ),
        g(
          id: 4,
          category: GarmentCategory.bottom,
          color: white,
          occasion: Occasion.work,
        ),
      ];
      final looks = lookOfTheDay(mixed, date: monday);
      expect(looks, isNotEmpty);
      expect(
        looks.every(
          (o) => o.garments.every((x) => x.occasion == Occasion.work),
        ),
        isTrue,
      );
    });

    test('unknown weather means summer; winter clothes are skipped', () {
      final wardrobe = [
        g(
          id: 1,
          category: GarmentCategory.top,
          color: blue,
          season: Season.winter,
        ),
        g(id: 2, category: GarmentCategory.bottom, color: white),
      ];
      expect(lookOfTheDay(wardrobe, date: monday), isEmpty);
      expect(
        lookOfTheDay(
          wardrobe,
          date: monday,
          weather: const Weather(temperatureC: 10, weatherCode: 0),
        ),
        isNotEmpty,
      );
    });

    test('rain moves a close look with outerwear up; dislikes stay out', () {
      final wardrobe = [
        g(id: 1, category: GarmentCategory.top, color: blue),
        g(id: 2, category: GarmentCategory.bottom, color: white),
        g(id: 3, category: GarmentCategory.outerwear, color: white),
      ];
      const rain = Weather(temperatureC: 28, weatherCode: 61);
      final rainy = lookOfTheDay(wardrobe, date: monday, weather: rain);
      expect(
        rainy.first.garments.any(
          (x) => x.category == GarmentCategory.outerwear,
        ),
        isTrue,
      );
      final disliked = lookOfTheDay(
        wardrobe,
        date: monday,
        weather: rain,
        excludedSignatures: {rainy.first.signature},
      );
      expect(
        disliked.map((o) => o.signature),
        isNot(contains(rainy.first.signature)),
      );
    });
  });
}
