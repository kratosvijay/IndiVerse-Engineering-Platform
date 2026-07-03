class KnowledgeLimits {
  final Duration maxIndexTime;
  final Duration maxSearchLatency;
  final int maxChunkSize;
  final int maxEmbeddingBatch;

  const KnowledgeLimits({
    this.maxIndexTime = const Duration(minutes: 5),
    this.maxSearchLatency = const Duration(milliseconds: 500),
    this.maxChunkSize = 1000,
    this.maxEmbeddingBatch = 100,
  });
}
