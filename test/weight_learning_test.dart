import 'package:flutter_test/flutter_test.dart';
import 'package:mi_armario/domain/models/garment.dart';
import 'package:mi_armario/domain/models/garment_color.dart';
import 'package:mi_armario/domain/models/outfit_feedback.dart';
import 'package:mi_armario/domain/outfit/scoring_weights.dart';
import 'package:mi_armario/domain/outfit/weight_learning.dart';

Garment g({
  required int id,
  required GarmentColor color,
  Occasion occasion = Occasion.casual,
  Season season = Season.all,
}) {
  return Garment(
    id: id,
    photoPath: '/p$id.jpg',
    thumbPath: '/t$id.jpg',
    category: GarmentCategory.top,
    colors: [color],
    occasion: occasion,
    season: season,
    createdAt: DateTime(2026, 1, 1),
  );
}

const red = GarmentColor(red: 255, green: 0, blue: 0, weight: 1);
const orange = GarmentColor(red: 255, green: 90, blue: 0, weight: 1);
const cyan = GarmentColor(red: 0, green: 255, blue: 255, weight: 1);
const white = GarmentColor(red: 255, green: 255, blue: 255, weight: 1);
const blue = GarmentColor(red: 0, green: 0, blue: 255, weight: 1);

OutfitFeedback fb(
  String signature,
  List<int> ids,
  FeedbackRating rating,
) {
  return OutfitFeedback(
    signature: signature,
    garmentIds: ids,
    rating: rating,
    createdAt: DateTime(2026, 1, 1),
  );
}

void expectWithinBounds(double value, double base) {
  expect(value, greaterThanOrEqualTo(base * 0.3));
  expect(value, lessThanOrEqualTo(base * 1.7));
}

void main() {
  const base = ScoringWeights.defaults();

  test('empty feedback returns base unchanged', () {
    final garments = [g(id: 1, color: red), g(id: 2, color: blue)];
    final learned = learnWeights(const [], garments, base: base);
    expect(learned.harmonyWeight, base.harmonyWeight);
    expect(learned.neutralBonus, base.neutralBonus);
    expect(learned.occasionBonus, base.occasionBonus);
    expect(learned.seasonBonus, base.seasonBonus);
    expect(learned.saturationClashPenalty, base.saturationClashPenalty);
    expect(learned.similarHuePenalty, base.similarHuePenalty);
    expect(learned.baseScore, base.baseScore);
  });

  test('likes on similar-hue outfits lower similarHuePenalty', () {
    final garments = [g(id: 1, color: red), g(id: 2, color: orange)];
    final feedback = [
      fb('1-2', [1, 2], FeedbackRating.like),
      fb('1-2b', [1, 2], FeedbackRating.like),
    ];
    final learned = learnWeights(feedback, garments, base: base);
    expect(learned.similarHuePenalty, lessThan(base.similarHuePenalty));
  });

  test('dislikes on clashing outfits raise saturationClashPenalty', () {
    final garments = [g(id: 1, color: red), g(id: 2, color: orange)];
    final feedback = [
      fb('1-2', [1, 2], FeedbackRating.dislike),
      fb('1-2b', [1, 2], FeedbackRating.dislike),
    ];
    final learned = learnWeights(feedback, garments, base: base);
    expect(
      learned.saturationClashPenalty,
      greaterThan(base.saturationClashPenalty),
    );
  });

  test('all learned weights stay within clamp bounds', () {
    final garments = [
      g(id: 1, color: red, occasion: Occasion.work, season: Season.winter),
      g(
        id: 2,
        color: orange,
        occasion: Occasion.work,
        season: Season.winter,
      ),
      g(id: 3, color: white, occasion: Occasion.work, season: Season.winter),
      g(id: 4, color: cyan, occasion: Occasion.party, season: Season.summer),
    ];
    final feedback = [
      fb('1-2', [1, 2], FeedbackRating.dislike),
      fb('1-2b', [1, 2], FeedbackRating.like),
      fb('1-3', [1, 3], FeedbackRating.like),
      fb('1-4', [1, 4], FeedbackRating.dislike),
    ];
    final learned = learnWeights(feedback, garments, base: base);
    expectWithinBounds(learned.neutralBonus, base.neutralBonus);
    expectWithinBounds(learned.occasionBonus, base.occasionBonus);
    expectWithinBounds(learned.seasonBonus, base.seasonBonus);
    expectWithinBounds(
      learned.saturationClashPenalty,
      base.saturationClashPenalty,
    );
    expectWithinBounds(learned.similarHuePenalty, base.similarHuePenalty);
  });

  test('feedback referencing missing garments is ignored', () {
    final garments = [g(id: 1, color: red)];
    final feedback = [fb('1-2', [1, 2], FeedbackRating.dislike)];
    final learned = learnWeights(feedback, garments, base: base);
    expect(learned.saturationClashPenalty, base.saturationClashPenalty);
    expect(learned.similarHuePenalty, base.similarHuePenalty);
    expect(learned.neutralBonus, base.neutralBonus);
    expect(learned.occasionBonus, base.occasionBonus);
    expect(learned.seasonBonus, base.seasonBonus);
  });
}
