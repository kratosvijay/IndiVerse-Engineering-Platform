import 'distributed_models.dart';

class WorkerRegistry {
  final Map<String, AgentWorker> registeredWorkers = {};

  void register(AgentWorker worker) {
    registeredWorkers[worker.id] = worker;
  }

  void unregister(String workerId) {
    registeredWorkers.remove(workerId);
  }

  List<AgentWorker> getWorkers() => registeredWorkers.values.toList();
}

class HeartbeatManager {
  final Map<String, DateTime> heartbeats = {};

  void recordHeartbeat(String workerId) {
    heartbeats[workerId] = DateTime.now();
  }

  // Evicts workers that haven't sent heartbeats in 10 seconds
  List<String> getStaleWorkers(List<AgentWorker> activeWorkers) {
    final now = DateTime.now();
    final stale = <String>[];
    for (final worker in activeWorkers) {
      final hb = heartbeats[worker.id] ?? worker.lastHeartbeat;
      if (now.difference(hb).inSeconds > 10) {
        stale.add(worker.id);
      }
    }
    return stale;
  }
}

class ClusterMetrics {
  double getAverageCpuUsage(List<AgentWorker> workers) {
    if (workers.isEmpty) return 0.0;
    final total = workers.fold<double>(0.0, (sum, w) => sum + w.cpuUsage);
    return total / workers.length;
  }

  double getAverageMemoryUsage(List<AgentWorker> workers) {
    if (workers.isEmpty) return 0.0;
    final total = workers.fold<double>(0.0, (sum, w) => sum + w.memoryUsage);
    return total / workers.length;
  }
}

class AgentCluster {
  final String clusterId;
  final WorkerRegistry registry;
  final HeartbeatManager heartbeatManager;
  final ClusterMetrics metrics;

  AgentCluster({
    required this.clusterId,
    WorkerRegistry? registry,
    HeartbeatManager? heartbeatManager,
    ClusterMetrics? metrics,
  })  : registry = registry ?? WorkerRegistry(),
        heartbeatManager = heartbeatManager ?? HeartbeatManager(),
        metrics = metrics ?? ClusterMetrics();

  void registerWorker(AgentWorker worker) {
    registry.register(worker);
    heartbeatManager.recordHeartbeat(worker.id);
  }

  void evictStaleWorkers() {
    final stale = heartbeatManager.getStaleWorkers(registry.getWorkers());
    for (final id in stale) {
      registry.unregister(id);
    }
  }
}
