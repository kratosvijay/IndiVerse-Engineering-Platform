import 'distributed_models.dart';

abstract interface class CloudProvider {
  CloudProviderType get type;
  Future<JobHandle> submit(ClusterJob job);
  Future<void> cancel(String jobId);
  Future<Map<String, dynamic>> inspect(String nodeId);
}

class LocalCloudProvider implements CloudProvider {
  @override
  CloudProviderType get type => CloudProviderType.local;

  @override
  Future<JobHandle> submit(ClusterJob job) async {
    return JobHandle(
      jobId: job.id,
      providerWorkerId: 'local-node-1',
      completionFuture: Future.delayed(const Duration(milliseconds: 100)),
    );
  }

  @override
  Future<void> cancel(String jobId) async {}

  @override
  Future<Map<String, dynamic>> inspect(String nodeId) async {
    return const {
      'nodeId': 'local-node-1',
      'active': true,
    };
  }
}

class DockerCloudProvider implements CloudProvider {
  @override
  CloudProviderType get type => CloudProviderType.docker;

  @override
  Future<JobHandle> submit(ClusterJob job) async {
    return JobHandle(
      jobId: job.id,
      providerWorkerId: 'docker-container-1',
      completionFuture: Future.delayed(const Duration(milliseconds: 200)),
    );
  }

  @override
  Future<void> cancel(String jobId) async {}

  @override
  Future<Map<String, dynamic>> inspect(String nodeId) async {
    return const {
      'containerId': 'docker-container-1',
      'image': 'indiverse-agent-worker:latest',
    };
  }
}
