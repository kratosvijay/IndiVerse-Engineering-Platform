class ContextContribution {
  final String providerId;
  final String content;
  final int tokens;
  final int priority;
  final String sourcePath;
  final double confidence;
  final double freshness;
  final String checksum;

  const ContextContribution({
    required this.providerId,
    required this.content,
    required this.tokens,
    required this.priority,
    required this.sourcePath,
    this.confidence = 1.0,
    this.freshness = 1.0,
    this.checksum = "",
  });
}

abstract class ContextProvider {
  Future<List<ContextContribution>> build(String rootPath);
}
