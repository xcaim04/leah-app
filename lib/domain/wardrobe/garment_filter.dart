import '../models/garment.dart';

List<Garment> filterGarments(
  List<Garment> items, {
  GarmentCategory? category,
  Occasion? occasion,
  Season? season,
}) {
  return items.where((g) {
    if (category != null && g.category != category) return false;
    if (occasion != null && g.occasion != occasion) return false;
    if (season != null && g.season != season) return false;
    return true;
  }).toList();
}
