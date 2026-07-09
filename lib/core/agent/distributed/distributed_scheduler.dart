import 'distributed_models.dart';

class DistributedScheduler {
  const DistributedScheduler();

  // Evaluates load, capability, queue, memory, and failure history to score workers
  double calculateAffinityScore(AgentWorker worker, ClusterJob job) {
    // 1. Verify capability match
    final caps = worker.capabilities;
    bool capabilityMatched = false;
    switch (job.stageName) {
      case 'planning':
        capabilityMatched = caps.planning;
      case 'generation':
        capabilityMatched = caps.generation;
      case 'verification':
        capabilityMatched = caps.verification;
      case 'deployment':
        capabilityMatched = caps.deployment;
      default:
        capabilityMatched = true;
    }

    if (!capabilityMatched) return -1.0; // unsuitable worker

    // 2. Score resources
    double score = 10.0;
    score -= (worker.cpuUsage * 0.05); // CPU deduction (max -5.0)
    score -= (worker.memoryUsage * 0.03); // Memory deduction
    score -= (worker.runningJobsCount * 1.0); // Queue deduction

    // 3. Affinity/locality checks
    if (job.targetWorkerId == worker.id) {
      score += 2.0; // Locality bonus
    }

    return score.clamp(0.0, 10.0);
  }

  // Schedules the job to the worker with the highest affinity score
  AgentWorker? selectWorker(List<AgentWorker> workers, ClusterJob job) {
    AgentWorker? bestWorker;
    double highestScore = -1.0;

    for (final worker in workers) {
      if (worker.state == WorkerState.offline ||
          worker.state == WorkerState.failed) {
        continue;
      }

      final score = calculateAffinityScore(worker, job);
      if (score > highestScore) {
        highestScore = score;
        bestWorker = worker;
      }
    }

    return bestWorker;
  }
}
