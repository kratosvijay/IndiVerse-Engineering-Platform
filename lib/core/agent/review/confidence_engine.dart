import 'review_models.dart';

class ConfidenceEngine {
  const ConfidenceEngine();

  ConfidenceScoreReport calculateHierarchicalConfidence({
    required double planning,
    required double generation,
    required double verification,
    required double repair,
    required double deployment,
    required double knowledge,
    required double reflection,
  }) {
    final overall = (planning +
            generation +
            verification +
            repair +
            deployment +
            knowledge +
            reflection) /
        7.0;
    return ConfidenceScoreReport(
      planning: planning,
      generation: generation,
      verification: verification,
      repair: repair,
      deployment: deployment,
      knowledge: knowledge,
      reflection: reflection,
      overall: overall,
    );
  }
}
