import 'package:flutter_test/flutter_test.dart';
import 'package:mi_armario/domain/models/garment.dart';
import 'package:mi_armario/domain/models/garment_color.dart';
import 'package:mi_armario/domain/models/wear_entry.dart';
import 'package:mi_armario/domain/stats/wardrobe_stats.dart';

final now = DateTime(2026, 6, 1);

Garment g(int id, GarmentCategory cat, {int r = 200, int gr = 30, int b = 30, int ageDays = 10}) => Garment(
      id: id,
      photoPath: 'p$id',
      thumbPath: 't$id',
      category: cat,
      colors: [GarmentColor(red: r, green: gr, blue: b, weight: 1)],
      occasion: Occasion.casual,
      season: Season.all,
      createdAt: now.subtract(Duration(days: ageDays)),
    );

WearEntry w(List<int> ids) =>
    WearEntry(signature: ids.join('-'), garmentIds: ids, wornOn: now);

void main() {
  test('counts, never worn and most worn ordering', () {
    final gs = [
      g(1, GarmentCategory.top),
      g(2, GarmentCategory.top),
      g(3, GarmentCategory.bottom),
    ];
    final s = computeStats(gs, [w([1, 3]), w([3]), w([3])], now);
    expect(s.total, 3);
    expect(s.categoryCounts[GarmentCategory.top], 2);
    expect(s.categoryCounts[GarmentCategory.footwear], 0);
    expect(s.mostWorn.map((e) => e.garment.id), [3, 1]);
    expect(s.mostWorn.first.times, 3);
    expect(s.neverWorn.single.garment.id, 2);
    expect(s.neverWorn.single.daysSinceAdded, 10);
    expect(s.colorFamilies.single.count, 3);
  });

  test('suggestions: footwear, tops ratio, stale', () {
    final gs = [
      for (var i = 0; i < 8; i++) g(i, GarmentCategory.top, ageDays: 90),
      g(100, GarmentCategory.bottom),
    ];
    final s = computeStats(gs, const [], now).suggestions;
    expect(s, contains('Añade calzado para completar más looks'));
    expect(s.any((e) => e.startsWith('Tienes 8 partes superiores y 1 inferior')), isTrue);
    expect(s.any((e) => e.contains('60 días')), isTrue);
    expect(computeStats(const [], const [], now).suggestions, isEmpty);
  });
}
