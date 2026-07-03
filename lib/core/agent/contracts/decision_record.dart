class DecisionRecord {
  final String id;
  final String version;
  final String reasoning;
  final List<String> knowledgeSources;
  final List<String> workspaceSources;
  final double confidence;
  final double estimatedCost;
  final int estimatedTokens;
  final String riskLevel;
  final String recommendedAction;

  const DecisionRecord({
    required this.id,
    required this.version,
    required this.reasoning,
    required this.knowledgeSources,
    required this.workspaceSources,
    required this.confidence,
    required this.estimatedCost,
    required this.estimatedTokens,
    required this.riskLevel,
    required this.recommendedAction,
  });
}
