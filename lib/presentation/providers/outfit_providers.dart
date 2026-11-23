import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/weather_service.dart';

import '../../domain/models/garment.dart';
import '../../domain/models/outfit.dart';
import '../../domain/models/outfit_feedback.dart';
import '../../domain/outfit/liked_outfits.dart';
import '../../domain/outfit/outfit_engine.dart' as engine;
import '../../domain/outfit/scoring_weights.dart';
import '../../domain/outfit/weight_learning.dart';
import '../../domain/today/look_of_the_day.dart';
import 'providers.dart';

class OutfitFilters {
  const OutfitFilters({this.occasion, this.season});

  final Occasion? occasion;
  final Season? season;
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
  final garments =
      ref.watch(garmentsProvider).asData?.value ?? const <Garment>[];
  final feedback =
      ref.watch(outfitFeedbackProvider).asData?.value ??
      const <OutfitFeedback>[];
  if (garments.isEmpty || feedback.isEmpty) return base;
  return learnWeights(feedback, garments, base: base);
});

final generatedOutfitsProvider = Provider<AsyncValue<List<Outfit>>>((ref) {
  final garmentsAsync = ref.watch(garmentsProvider);
  final filters = ref.watch(outfitFiltersProvider);
  final weights = ref.watch(scoringWeightsProvider);
  final disliked = ref.watch(dislikedSignaturesProvider);
  return garmentsAsync.whenData(
    (garments) => engine.generate(
      garments,
      occasion: filters.occasion,
      season: filters.season,
      weights: weights,
      limit: 20,
      excludedSignatures: disliked,
    ),
  );
});

/// Every look currently liked, independent of the Looks tab's filters/top-N.
final likedOutfitsProvider = Provider<AsyncValue<List<Outfit>>>((ref) {
  final weights = ref.watch(scoringWeightsProvider);
  final feedback =
      ref.watch(outfitFeedbackProvider).asData?.value ??
      const <OutfitFeedback>[];
  return ref
      .watch(garmentsProvider)
      .whenData((garments) => likedOutfits(feedback, garments, weights));
});

/// Signatures of looks she disliked; never suggested again.
final dislikedSignaturesProvider = Provider<Set<String>>(
  (ref) => {
    for (final e in ref.watch(latestRatingsProvider).entries)
      if (e.value == FeedbackRating.dislike) e.key,
  },
);

final weatherServiceProvider = Provider<WeatherService>(
  (ref) => OpenMeteoWeatherService(ref.watch(settingsRepositoryProvider)),
);

/// Fetched once per session; null = unknown (fallback: warm weather).
final todayWeatherProvider = FutureProvider<Weather?>(
  (ref) => ref.watch(weatherServiceProvider).current(),
);

/// Today's suggestions. Uses the warm fallback while the weather loads, then
/// recomputes when it arrives.
final lookOfTheDayProvider = Provider<AsyncValue<List<Outfit>>>((ref) {
  final weather = ref.watch(todayWeatherProvider).asData?.value;
  final weights = ref.watch(scoringWeightsProvider);
  final disliked = ref.watch(dislikedSignaturesProvider);
  return ref
      .watch(garmentsProvider)
      .whenData(
        (garments) => lookOfTheDay(
          garments,
          date: DateTime.now(),
          weather: weather,
          weights: weights,
          excludedSignatures: disliked,
        ),
      );
});

final latestRatingsProvider = Provider<Map<String, FeedbackRating>>((ref) {
  final feedback =
      ref.watch(outfitFeedbackProvider).asData?.value ??
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
    await repository.replace(feedback);
    _ref.invalidate(outfitFeedbackProvider);
  }
}

final feedbackControllerProvider = Provider<OutfitFeedbackController>(
  (ref) => OutfitFeedbackController(ref),
);
