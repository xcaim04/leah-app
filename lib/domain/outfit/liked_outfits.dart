import '../models/garment.dart';
import '../models/outfit.dart';
import '../models/outfit_feedback.dart';
import 'outfit_explainer.dart';
import 'outfit_scorer.dart';
import 'scoring_weights.dart';

/// Looks whose latest rating is a like, rebuilt from their garments (so they
/// don't depend on the generator's top-N). [feedback] is newest first.
List<Outfit> likedOutfits(
  List<OutfitFeedback> feedback,
  List<Garment> garments,
  ScoringWeights weights,
) {
  final byId = {for (final g in garments) g.id: g};
  final seen = <String>{};
  final result = <Outfit>[];
  for (final entry in feedback) {
    if (!seen.add(entry.signature)) continue;
    if (entry.rating != FeedbackRating.like) continue;
    final items = [for (final id in entry.garmentIds) byId[id]];
    if (items.isEmpty || items.contains(null)) continue;
    final looks = items.cast<Garment>();
    final scored = scoreWithDetails(looks, weights);
    result.add(
      Outfit(
        garments: looks,
        score: scored.score,
        explanation: explainOutfit(
          looks,
          scored.dominantHarmony,
          occasion: looks.first.occasion,
          season: looks.first.season,
        ),
      ),
    );
  }
  result.sort((a, b) => b.score.compareTo(a.score));
  return result;
}
