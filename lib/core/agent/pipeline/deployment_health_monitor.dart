import 'pipeline_models.dart';

class DeploymentHealthMonitor {
  const DeploymentHealthMonitor();

  // Evaluates operational metrics and computes derived health score
  HealthSnapshot recordMetrics({
    required double availability,
    required double crashRate,
    required double errorRate,
    required double responseTimeMs,
    required double resourceUsage,
  }) {
    // Availability yields positive weight, crashRate/errorRate deduct score
    double baseScore = availability * 10.0;
    baseScore -= (crashRate * 0.5);
    baseScore -= (errorRate * 0.3);
    if (responseTimeMs > 500) {
      baseScore -= 1.0;
    }

    final score = baseScore.clamp(0.0, 10.0);

    return HealthSnapshot(
      availability: availability,
      crashRate: crashRate,
      errorRate: errorRate,
      responseTimeMs: responseTimeMs,
      resourceUsage: resourceUsage,
      healthScore: score,
      timestamp: DateTime.now(),
    );
  }
}
