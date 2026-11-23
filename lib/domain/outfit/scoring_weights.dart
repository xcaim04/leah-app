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

}
