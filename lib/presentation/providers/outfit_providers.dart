import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/garment.dart';
import '../../domain/models/outfit.dart';
import '../../domain/outfit/outfit_engine.dart' as engine;
import '../../domain/outfit/scoring_weights.dart';
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

final scoringWeightsProvider = Provider<ScoringWeights>(
  (ref) => const ScoringWeights.defaults(),
);

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
