import 'package:flutter_test/flutter_test.dart';
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
        outfits.any(
          (o) =>
              o.garments.length == 2 &&
              o.garments.any((x) => x.category == GarmentCategory.top) &&
              o.garments.any((x) => x.category == GarmentCategory.bottom),
        ),
        isTrue,
      );
    });

    test('excluded (disliked) outfits are dropped before the limit', () {
      final garments = [
        g(id: 1, category: GarmentCategory.top, color: blue),
        g(id: 2, category: GarmentCategory.bottom, color: white),
        g(id: 3, category: GarmentCategory.bottom, color: red),
      ];
      final best = generate(garments, limit: 1).single;
      final next = generate(
        garments,
        limit: 1,
        excludedSignatures: {best.signature},
      );
      expect(next.single.signature, isNot(best.signature));
      expect(
        generate(garments).map((o) => o.signature),
        contains(best.signature),
      );
    });

    test('creates dress+footwear outfits', () {
      final garments = [
        g(id: 1, category: GarmentCategory.dress, color: red),
        g(id: 2, category: GarmentCategory.footwear, color: white),
      ];
      final outfits = generate(garments, limit: 10);
      expect(
        outfits.any(
          (o) =>
              o.garments.any((x) => x.category == GarmentCategory.dress) &&
              o.garments.any((x) => x.category == GarmentCategory.footwear),
        ),
        isTrue,
      );
    });

    test('filters by occasion and season', () {
      final garments = [
        g(
          id: 1,
          category: GarmentCategory.top,
          color: blue,
          occasion: Occasion.work,
          season: Season.winter,
        ),
        g(
          id: 2,
          category: GarmentCategory.bottom,
          color: white,
          occasion: Occasion.work,
          season: Season.winter,
        ),
        g(
          id: 3,
          category: GarmentCategory.top,
          color: red,
          occasion: Occasion.party,
          season: Season.summer,
        ),
        g(
          id: 4,
          category: GarmentCategory.bottom,
          color: green,
          occasion: Occasion.party,
          season: Season.summer,
        ),
      ];
      final outfits = generate(
        garments,
        occasion: Occasion.work,
        season: Season.winter,
        limit: 10,
      );
      expect(outfits, isNotEmpty);
      for (final o in outfits) {
        expect(o.garments.every((x) => x.occasion == Occasion.work), isTrue);
        expect(
          o.garments.every((x) => x.season.isCompatibleWith(Season.winter)),
          isTrue,
        );
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

    test('limited results equal the top of the full list, explained', () {
      final garments = [
        g(id: 1, category: GarmentCategory.top, color: blue),
        g(id: 2, category: GarmentCategory.top, color: red),
        g(id: 3, category: GarmentCategory.bottom, color: white),
        g(id: 4, category: GarmentCategory.bottom, color: cyan),
        g(id: 5, category: GarmentCategory.footwear, color: green),
        g(id: 6, category: GarmentCategory.outerwear, color: red),
        g(id: 7, category: GarmentCategory.dress, color: blue),
      ];
      final all = generate(garments, limit: 0);
      final top = generate(garments, limit: 5);
      expect(top, hasLength(5));
      expect(
        top.map((o) => (o.signature, o.score)),
        all.take(5).map((o) => (o.signature, o.score)),
      );
      for (final o in all) {
        expect(o.explanation, isNotEmpty);
        // A dress alone scored 0 and was never a real look.
        expect(o.garments.length, greaterThanOrEqualTo(2));
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
      // Good looks must not all saturate at 100% (scores were clamped before).
      expect(complementary.first.score, lessThan(1));
      expect(neutral.first.score, lessThan(1));
    });
  });

  group('recently worn', () {
    test('penalty drops a recently worn look below an equal one', () {
      final garments = [
        g(id: 1, category: GarmentCategory.top, color: blue),
        g(id: 2, category: GarmentCategory.bottom, color: white),
        g(id: 3, category: GarmentCategory.bottom, color: white),
      ];
      final fresh = generate(garments);
      expect(fresh[0].score, fresh[1].score);

      final outfits = generate(garments, recentlyWorn: {2});
      expect(outfits.first.signature, '1-3');
      expect(outfits.last.signature, '1-2');
      expect(
        outfits.last.score,
        closeTo(fresh.first.score - recentlyWornPenalty, 1e-9),
      );
    });
  });

  group('accessories', () {
    test('adds the accessory when it improves the look', () {
      final outfits = generate([
        g(id: 1, category: GarmentCategory.top, color: red),
        g(id: 2, category: GarmentCategory.bottom, color: green),
        g(id: 3, category: GarmentCategory.accessory, color: white),
      ]);
      final base = generate([
        g(id: 1, category: GarmentCategory.top, color: red),
        g(id: 2, category: GarmentCategory.bottom, color: green),
      ]).single;
      final look = outfits.single;
      expect(look.signature, '1-2-3');
      expect(look.score, greaterThan(base.score));
      expect(look.explanation, isNotEmpty);
    });

    test('skips an accessory that would lower the score', () {
      final outfits = generate([
        g(id: 1, category: GarmentCategory.top, color: red),
        g(id: 2, category: GarmentCategory.bottom, color: white),
        g(
          id: 3,
          category: GarmentCategory.accessory,
          color: green,
          occasion: Occasion.party,
        ),
      ]);
      expect(outfits.single.signature, '1-2');
    });

    test('accessories are never a look on their own', () {
      final outfits = generate([
        g(id: 1, category: GarmentCategory.accessory, color: red),
        g(id: 2, category: GarmentCategory.accessory, color: white),
      ]);
      expect(outfits, isEmpty);
    });
  });
}
