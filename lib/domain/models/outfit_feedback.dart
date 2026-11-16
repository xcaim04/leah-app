import 'dart:convert';

/// User rating for a suggested outfit.
enum FeedbackRating { like, dislike }

extension FeedbackRatingX on FeedbackRating {
  int get value => this == FeedbackRating.like ? 1 : -1;

  static FeedbackRating fromValue(int value) =>
      value >= 0 ? FeedbackRating.like : FeedbackRating.dislike;
}

class OutfitFeedback {
  const OutfitFeedback({
    this.id,
    required this.signature,
    required this.garmentIds,
    required this.rating,
    required this.createdAt,
  });

  final int? id;
  final String signature;
  final List<int> garmentIds;
  final FeedbackRating rating;
  final DateTime createdAt;

  Map<String, Object?> toMap() => <String, Object?>{
        if (id != null) 'id': id,
        'signature': signature,
        'garment_ids': jsonEncode(garmentIds),
        'rating': rating.value,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory OutfitFeedback.fromMap(Map<String, Object?> map) => OutfitFeedback(
        id: map['id'] as int?,
        signature: map['signature'] as String,
        garmentIds: (jsonDecode(map['garment_ids'] as String) as List<dynamic>)
            .map((e) => (e as num).toInt())
            .toList(),
        rating: FeedbackRatingX.fromValue(map['rating'] as int),
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      );
}
