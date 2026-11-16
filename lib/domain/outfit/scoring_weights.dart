class ScoringWeights {
  const ScoringWeights({
    required this.harmonyWeight,
    required this.neutralBonus,
    required this.occasionBonus,
    required this.seasonBonus,
    required this.saturationClashPenalty,
    required this.similarHuePenalty,
    required this.baseScore,
  });

  const ScoringWeights.defaults()
      : harmonyWeight = 1.0,
        neutralBonus = 0.08,
        occasionBonus = 0.12,
        seasonBonus = 0.1,
        saturationClashPenalty = 0.18,
        similarHuePenalty = 0.12,
        baseScore = 0.2;

  final double harmonyWeight;
  final double neutralBonus;
  final double occasionBonus;
  final double seasonBonus;
  final double saturationClashPenalty;
  final double similarHuePenalty;
  final double baseScore;

  ScoringWeights copyWith({
    double? harmonyWeight,
    double? neutralBonus,
    double? occasionBonus,
    double? seasonBonus,
    double? saturationClashPenalty,
    double? similarHuePenalty,
    double? baseScore,
  }) {
    return ScoringWeights(
      harmonyWeight: harmonyWeight ?? this.harmonyWeight,
      neutralBonus: neutralBonus ?? this.neutralBonus,
      occasionBonus: occasionBonus ?? this.occasionBonus,
      seasonBonus: seasonBonus ?? this.seasonBonus,
      saturationClashPenalty:
          saturationClashPenalty ?? this.saturationClashPenalty,
      similarHuePenalty: similarHuePenalty ?? this.similarHuePenalty,
      baseScore: baseScore ?? this.baseScore,
    );
  }
}
