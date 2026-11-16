import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/garment.dart';
import '../../domain/models/outfit.dart';
import '../../domain/models/outfit_feedback.dart';
import '../../domain/outfit/outfit_engine.dart' as engine;
import '../../domain/outfit/scoring_weights.dart';
import '../../domain/outfit/weight_learning.dart';
import 'providers.dart';

class OutfitFilters {
  const OutfitFilters({this.occasion, this.season});

  final Occasion? occasion;
  final Season? season;

  OutfitFilters copyWith({
    Occasion? Function()? occasion,
    Season? Function()? season,
  }) {
    return OutfitFilters(
      occasion: occasion != null ? occasion() : this.occasion,
      season: season != null ? season() : this.season,
    );
  }
}

class OutfitFiltersNotifier extends StateNotifier<OutfitFilters> {
  OutfitFiltersNotifier() : super(const OutfitFilters());

  void setOccasion(Occasion? occasion) {
    state = OutfitFilters(occasion: occasion, season: state.season);
  }

  void setSeason(Season? season) {
    state = OutfitFilters(occasion: state.occasion, season: season);
  }

  void clear() {
    state = const OutfitFilters();
  }
}

final outfitFiltersProvider =
    StateNotifierProvider<OutfitFiltersNotifier, OutfitFilters>(
  (ref) => OutfitFiltersNotifier(),
);

final scoringWeightsProvider = Provider<ScoringWeights>((ref) {
  const base = ScoringWeights.defaults();
  final garments = ref.watch(garmentsProvider).asData?.value ?? const <Garment>[];
  final feedback =
      ref.watch(outfitFeedbackProvider).asData?.value ?? const <OutfitFeedback>[];
  if (garments.isEmpty || feedback.isEmpty) return base;
  return learnWeights(feedback, garments, base: base);
});

final generatedOutfitsProvider = Provider<AsyncValue<List<Outfit>>>((ref) {
  final garmentsAsync = ref.watch(garmentsProvider);
  final filters = ref.watch(outfitFiltersProvider);
  final weights = ref.watch(scoringWeightsProvider);
  return garmentsAsync.whenData(
    (garments) => engine.generate(
      garments,
      occasion: filters.occasion,
      season: filters.season,
      weights: weights,
      limit: 20,
    ),
  );
});

final latestRatingsProvider = Provider<Map<String, FeedbackRating>>((ref) {
  final feedback = ref.watch(outfitFeedbackProvider).asData?.value ??
      const <OutfitFeedback>[];
  final result = <String, FeedbackRating>{};
  for (final entry in feedback) {
    result.putIfAbsent(entry.signature, () => entry.rating);
  }
  return result;
});

class OutfitFeedbackController {
  OutfitFeedbackController(this._ref);

  final Ref _ref;

  Future<void> like(Outfit outfit) => _setRating(outfit, FeedbackRating.like);

  Future<void> dislike(Outfit outfit) =>
      _setRating(outfit, FeedbackRating.dislike);

  Future<void> _setRating(Outfit outfit, FeedbackRating rating) async {
    final repository = _ref.read(outfitFeedbackRepositoryProvider);
    final feedback = OutfitFeedback(
      signature: outfit.signature,
      garmentIds: outfit.garmentIds,
      rating: rating,
      createdAt: DateTime.now(),
    );
    await repository.deleteBySignature(outfit.signature);
    await repository.insert(feedback);
    _ref.invalidate(outfitFeedbackProvider);
  }
}

final feedbackControllerProvider = Provider<OutfitFeedbackController>(
  (ref) => OutfitFeedbackController(ref),
);
