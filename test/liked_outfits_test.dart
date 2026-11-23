import 'package:flutter_test/flutter_test.dart';
import 'package:mi_armario/domain/models/garment.dart';
import 'package:mi_armario/domain/models/garment_color.dart';
import 'package:mi_armario/domain/models/outfit_feedback.dart';
import 'package:mi_armario/domain/outfit/liked_outfits.dart';
import 'package:mi_armario/domain/outfit/scoring_weights.dart';

Garment g(int id, GarmentCategory category, GarmentColor color) => Garment(
  id: id,
  photoPath: '/p$id.jpg',
  thumbPath: '/t$id.jpg',
  category: category,
  colors: [color],
  occasion: Occasion.casual,
  season: Season.all,
  createdAt: DateTime(2026, 1, 1),
);

OutfitFeedback fb(List<int> ids, FeedbackRating rating, int day) =>
    OutfitFeedback(
      signature: (ids.toList()..sort()).join('-'),
      garmentIds: ids,
      rating: rating,
      createdAt: DateTime(2026, 1, day),
    );

const red = GarmentColor(red: 255, green: 0, blue: 0, weight: 1);
const blue = GarmentColor(red: 0, green: 0, blue: 255, weight: 1);
const white = GarmentColor(red: 255, green: 255, blue: 255, weight: 1);
const weights = ScoringWeights.defaults();

void main() {
  final top = g(1, GarmentCategory.top, red);
  final bottom = g(2, GarmentCategory.bottom, blue);

  test('liked look is returned even with many better-scoring garments', () {
    final garments = [
      top,
      bottom,
      for (var i = 0; i < 25; i++) ...[
        g(10 + i * 2, GarmentCategory.top, white),
        g(11 + i * 2, GarmentCategory.bottom, white),
      ],
    ];
    final result = likedOutfits(
      [fb([1, 2], FeedbackRating.like, 1)],
      garments,
      weights,
    );
    expect(result.single.signature, '1-2');
  });

  test('disliked after liked is not returned', () {
    final result = likedOutfits(
      [fb([1, 2], FeedbackRating.dislike, 2), fb([1, 2], FeedbackRating.like, 1)],
      [top, bottom],
      weights,
    );
    expect(result, isEmpty);
  });

  test('look with a deleted garment is skipped', () {
    final result = likedOutfits(
      [fb([1, 2], FeedbackRating.like, 1)],
      [top],
      weights,
    );
    expect(result, isEmpty);
  });
}
