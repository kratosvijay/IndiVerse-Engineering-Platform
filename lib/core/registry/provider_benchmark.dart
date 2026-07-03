class ProviderBenchmark {
  final double averageLatencyMs;
  final double reliabilityRate;
  final double averageCost;
  final double rateLimitErrorRate;
  final double p50LatencyMs;
  final double p95LatencyMs;
  final double p99LatencyMs;

  const ProviderBenchmark({
    this.averageLatencyMs = 0.0,
    this.reliabilityRate = 1.0,
    this.averageCost = 0.0,
    this.rateLimitErrorRate = 0.0,
    this.p50LatencyMs = 0.0,
    this.p95LatencyMs = 0.0,
    this.p99LatencyMs = 0.0,
  });
}
