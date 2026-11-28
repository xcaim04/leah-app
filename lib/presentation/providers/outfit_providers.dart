import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/weather_service.dart';

import '../../domain/models/garment.dart';
import '../../domain/models/outfit.dart';
import '../../domain/models/outfit_feedback.dart';
import '../../domain/models/wear_entry.dart';
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
  final worn = ref.watch(recentlyWornProvider);
  return garmentsAsync.whenData(
    (garments) => engine.generate(
      garments,
      occasion: filters.occasion,
      season: filters.season,
      weights: weights,
      limit: 20,
      excludedSignatures: disliked,
      recentlyWorn: worn,
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
  final worn = ref.watch(recentlyWornProvider);
  return ref
      .watch(garmentsProvider)
      .whenData(
        (garments) => lookOfTheDay(
          garments,
          date: DateTime.now(),
          weather: weather,
          weights: weights,
          excludedSignatures: disliked,
          recentlyWorn: worn,
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

  /// Forgets the vote: the look leaves Favoritos but can be suggested again.
  Future<void> clear(Outfit outfit) async {
    await _ref
        .read(outfitFeedbackRepositoryProvider)
        .deleteBySignature(outfit.signature);
    _ref.invalidate(outfitFeedbackProvider);
  }

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

/// Garments worn in the 3 days before today (penalised in suggestions).
/// Today is left out so logging a look doesn't reshuffle the card she tapped.
final recentlyWornProvider = Provider<Set<int>>((ref) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final since = DateTime(now.year, now.month, now.day - 3);
  return {
    for (final e
        in ref.watch(wearLogProvider).asData?.value ?? const <WearEntry>[])
      if (!e.wornOn.isBefore(since) && e.wornOn.isBefore(today))
        ...e.garmentIds,
  };
});

/// Today's wear-log entry per look signature ("Me lo puse hoy").
final wornTodayProvider = Provider<Map<String, WearEntry>>((ref) {
  final today = WearEntry.dayKey(DateTime.now());
  return {
    for (final e
        in ref.watch(wearLogProvider).asData?.value ?? const <WearEntry>[])
      if (WearEntry.dayKey(e.wornOn) == today) e.signature: e,
  };
});

class WearLogController {
  WearLogController(this._ref);

  final Ref _ref;

  Future<void> wearToday(Outfit outfit) async {
    final now = DateTime.now();
    await _ref
        .read(wearLogRepositoryProvider)
        .add(
          WearEntry(
            signature: outfit.signature,
            garmentIds: outfit.garmentIds,
            wornOn: DateTime(now.year, now.month, now.day),
          ),
        );
    _ref.invalidate(wearLogProvider);
  }

  Future<void> delete(int id) async {
    await _ref.read(wearLogRepositoryProvider).deleteById(id);
    _ref.invalidate(wearLogProvider);
  }
}

final wearLogControllerProvider = Provider<WearLogController>(
  (ref) => WearLogController(ref),
);

final feedbackControllerProvider = Provider<OutfitFeedbackController>(
  (ref) => OutfitFeedbackController(ref),
);
