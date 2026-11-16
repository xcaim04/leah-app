import 'package:test/test.dart';
import 'package:mi_armario/domain/models/garment.dart';
import 'package:mi_armario/domain/models/garment_color.dart';
import 'package:mi_armario/domain/outfit/outfit_engine.dart';
import 'package:mi_armario/domain/outfit/scoring_weights.dart';

Garment g({
  required int id,
  required GarmentCategory category,
  required GarmentColor color,
  Occasion occasion = Occasion.casual,
  Season season = Season.all,
}) {
  return Garment(
    id: id,
    photoPath: '/p$id.jpg',
    thumbPath: '/t$id.jpg',
    category: category,
    colors: [color],
    occasion: occasion,
    season: season,
    createdAt: DateTime(2026, 1, 1),
  );
}

const red = GarmentColor(red: 255, green: 0, blue: 0, weight: 1);
const blue = GarmentColor(red: 0, green: 0, blue: 255, weight: 1);
const white = GarmentColor(red: 255, green: 255, blue: 255, weight: 1);
const cyan = GarmentColor(red: 0, green: 255, blue: 255, weight: 1);
const green = GarmentColor(red: 0, green: 255, blue: 0, weight: 1);

void main() {
  group('generate', () {
    test('creates top+bottom outfits', () {
      final garments = [
        g(id: 1, category: GarmentCategory.top, color: blue),
        g(id: 2, category: GarmentCategory.bottom, color: white),
      ];
      final outfits = generate(garments, limit: 10);
      expect(outfits, isNotEmpty);
      expect(
        outfits.any((o) =>
            o.garments.length == 2 &&
            o.garments.any((x) => x.category == GarmentCategory.top) &&
            o.garments.any((x) => x.category == GarmentCategory.bottom)),
        isTrue,
      );
    });

    test('creates dress+footwear outfits', () {
      final garments = [
        g(id: 1, category: GarmentCategory.dress, color: red),
        g(id: 2, category: GarmentCategory.footwear, color: white),
      ];
      final outfits = generate(garments, limit: 10);
      expect(
        outfits.any((o) =>
            o.garments.any((x) => x.category == GarmentCategory.dress) &&
            o.garments.any((x) => x.category == GarmentCategory.footwear)),
        isTrue,
      );
    });

    test('filters by occasion and season', () {
      final garments = [
        g(id: 1, category: GarmentCategory.top, color: blue, occasion: Occasion.work, season: Season.winter),
        g(id: 2, category: GarmentCategory.bottom, color: white, occasion: Occasion.work, season: Season.winter),
        g(id: 3, category: GarmentCategory.top, color: red, occasion: Occasion.party, season: Season.summer),
        g(id: 4, category: GarmentCategory.bottom, color: green, occasion: Occasion.party, season: Season.summer),
      ];
      final outfits = generate(garments, occasion: Occasion.work, season: Season.winter, limit: 10);
      expect(outfits, isNotEmpty);
      for (final o in outfits) {
        expect(o.garments.every((x) => x.occasion == Occasion.work), isTrue);
        expect(o.garments.every((x) => x.season.isCompatibleWith(Season.winter)), isTrue);
      }
    });

    test('respects limit and sorts by score desc', () {
      final garments = [
        g(id: 1, category: GarmentCategory.top, color: blue),
        g(id: 2, category: GarmentCategory.bottom, color: white),
        g(id: 3, category: GarmentCategory.footwear, color: cyan),
        g(id: 4, category: GarmentCategory.outerwear, color: red),
      ];
      final outfits = generate(garments, limit: 2);
      expect(outfits.length, lessThanOrEqualTo(2));
      for (var i = 1; i < outfits.length; i++) {
        expect(outfits[i - 1].score >= outfits[i].score, isTrue);
      }
    });

    test('harmony affects score (complementary vs clash context)', () {
      final complementary = generate([
        g(id: 1, category: GarmentCategory.top, color: red),
        g(id: 2, category: GarmentCategory.bottom, color: cyan),
      ], weights: const ScoringWeights.defaults());
      final neutral = generate([
        g(id: 1, category: GarmentCategory.top, color: red),
        g(id: 2, category: GarmentCategory.bottom, color: white),
      ], weights: const ScoringWeights.defaults());
      expect(complementary.first.score, greaterThan(0));
      expect(neutral.first.score, greaterThan(0));
    });
  });
}
