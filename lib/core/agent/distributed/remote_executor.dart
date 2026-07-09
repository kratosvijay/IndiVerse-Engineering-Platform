import 'distributed_models.dart';
import 'cloud_provider.dart';

class RemoteExecutor {
  final CloudProvider provider;

  const RemoteExecutor({
    required this.provider,
  });

  Future<JobHandle> execute(ClusterJob job) async {
    return provider.submit(job);
  }

  Future<void> cancelJob(String jobId) async {
    await provider.cancel(jobId);
  }
}
