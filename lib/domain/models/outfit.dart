import 'garment.dart';

/// A generated combination of garments with a score and a short explanation.
class Outfit {
  const Outfit({
    required this.garments,
    required this.score,
    required this.explanation,
  });

  final List<Garment> garments;
  final double score;
  final String explanation;

  /// Stable, order-independent identifier used to attach feedback.
  String get signature {
    final ids = garments.map((g) => g.id).whereType<int>().toList()..sort();
    return ids.join('-');
  }

  List<int> get garmentIds =>
      garments.map((g) => g.id).whereType<int>().toList();
}
