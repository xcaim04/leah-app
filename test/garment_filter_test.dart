import 'package:flutter_test/flutter_test.dart';
import 'package:mi_armario/domain/models/garment.dart';
import 'package:mi_armario/domain/models/garment_color.dart';
import 'package:mi_armario/domain/wardrobe/garment_filter.dart';

Garment _g({
  required int id,
  required GarmentCategory category,
  required Occasion occasion,
  required Season season,
}) {
  return Garment(
    id: id,
    photoPath: '/p/$id.jpg',
    thumbPath: '/t/$id.jpg',
    category: category,
    colors: const [GarmentColor(red: 0, green: 0, blue: 0, weight: 1)],
    occasion: occasion,
    season: season,
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  group('filterGarments', () {
    final items = [
      _g(id: 1, category: GarmentCategory.top, occasion: Occasion.casual, season: Season.summer),
      _g(id: 2, category: GarmentCategory.bottom, occasion: Occasion.work, season: Season.winter),
      _g(id: 3, category: GarmentCategory.top, occasion: Occasion.work, season: Season.summer),
    ];

    test('returns all when no filters', () {
      expect(filterGarments(items).map((e) => e.id), [1, 2, 3]);
    });

    test('filters by category', () {
      expect(
        filterGarments(items, category: GarmentCategory.top).map((e) => e.id),
        [1, 3],
      );
    });

    test('filters by multiple criteria', () {
      expect(
        filterGarments(
          items,
          category: GarmentCategory.top,
          occasion: Occasion.work,
          season: Season.summer,
        ).map((e) => e.id),
        [3],
      );
    });

    test('returns empty list when nothing matches', () {
      expect(
        filterGarments(items, category: GarmentCategory.dress),
        isEmpty,
      );
    });
  });
}
