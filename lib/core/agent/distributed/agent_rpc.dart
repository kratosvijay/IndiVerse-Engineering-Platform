import 'distributed_models.dart';
import 'remote_executor.dart';

class AgentRPC {
  final RemoteExecutor executor;

  const AgentRPC({
    required this.executor,
  });

  Future<JobHandle> routeJob(ClusterJob job) async {
    // Routes job request to the remote executor
    return executor.execute(job);
  }
}
