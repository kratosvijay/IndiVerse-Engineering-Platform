enum CloudProviderType {
  local,
  docker,
  ssh,
  kubernetes,
  vm
}

enum LeaseType {
  workspace,
  file,
  section
}

enum WorkerState {
  starting,
  healthy,
  busy,
  draining,
  offline,
  failed
}

enum ClusterJobState {
  queued,
  scheduled,
  dispatching,
  running,
  waiting,
  retrying,
  completed,
  failed,
  cancelled
}

class WorkerCapabilities {
  final bool planning;
  final bool generation;
  final bool verification;
  final bool deployment;
  final List<String> languages;
  final List<String> tools;
  final int cpuCores;
  final int ramMb;
  final bool gpu;

  const WorkerCapabilities({
    required this.planning,
    required this.generation,
    required this.verification,
    required this.deployment,
    required this.languages,
    required this.tools,
    required this.cpuCores,
    required this.ramMb,
    required this.gpu,
  });

  Map<String, dynamic> toJson() => {
        'planning': planning,
        'generation': generation,
        'verification': verification,
        'deployment': deployment,
        'languages': languages,
        'tools': tools,
        'cpuCores': cpuCores,
        'ramMb': ramMb,
        'gpu': gpu,
      };
}

class AgentWorker {
  final String id;
  final String clusterId;
  final String nodeId;
  final WorkerState state;
  final WorkerCapabilities capabilities;
  final double cpuUsage;
  final double memoryUsage;
  final int runningJobsCount;
  final DateTime lastHeartbeat;
  final String version;

  const AgentWorker({
    required this.id,
    required this.clusterId,
    required this.nodeId,
    required this.state,
    required this.capabilities,
    required this.cpuUsage,
    required this.memoryUsage,
    required this.runningJobsCount,
    required this.lastHeartbeat,
    required this.version,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'clusterId': clusterId,
        'nodeId': nodeId,
        'state': state.name,
        'capabilities': capabilities.toJson(),
        'cpuUsage': cpuUsage,
        'memoryUsage': memoryUsage,
        'runningJobsCount': runningJobsCount,
        'lastHeartbeat': lastHeartbeat.toIso8601String(),
        'version': version,
      };
}

class ClusterJob {
  final String id;
  final String clusterId;
  final String targetWorkerId;
  final String stageName;
  final ClusterJobState state;
  final int priority;
  final Map<String, dynamic> arguments;
  final DateTime createdAt;

  const ClusterJob({
    required this.id,
    required this.clusterId,
    required this.targetWorkerId,
    required this.stageName,
    required this.state,
    required this.priority,
    required this.arguments,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'clusterId': clusterId,
        'targetWorkerId': targetWorkerId,
        'stageName': stageName,
        'state': state.name,
        'priority': priority,
        'arguments': arguments,
        'createdAt': createdAt.toIso8601String(),
      };
}

class WorkspaceLease {
  final String leaseId;
  final LeaseType type;
  final String resourcePath;
  final String ownerAgentId;
  final int leaseVersion;
  final DateTime acquiredAt;
  final DateTime expiresAt;
  final int renewCount;

  const WorkspaceLease({
    required this.leaseId,
    required this.type,
    required this.resourcePath,
    required this.ownerAgentId,
    required this.leaseVersion,
    required this.acquiredAt,
    required this.expiresAt,
    required this.renewCount,
  });

  Map<String, dynamic> toJson() => {
        'leaseId': leaseId,
        'type': type.name,
        'resourcePath': resourcePath,
        'ownerAgentId': ownerAgentId,
        'leaseVersion': leaseVersion,
        'acquiredAt': acquiredAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
        'renewCount': renewCount,
      };
}

class FederatedKnowledgeDocument {
  final String id;
  final String title;
  final String content;
  final String sourceNodeId;
  final Map<String, dynamic> tags;

  const FederatedKnowledgeDocument({
    required this.id,
    required this.title,
    required this.content,
    required this.sourceNodeId,
    required this.tags,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'sourceNodeId': sourceNodeId,
        'tags': tags,
      };
}

class JobHandle {
  final String jobId;
  final String providerWorkerId;
  final Future<void> completionFuture;

  const JobHandle({
    required this.jobId,
    required this.providerWorkerId,
    required this.completionFuture,
  });
}

// Sealed Event Hierarchy
sealed class ClusterEvent {
  final String id;
  final DateTime timestamp;

  const ClusterEvent({
    required this.id,
    required this.timestamp,
  });

  Map<String, dynamic> toJson();
}

class WorkerRegistered extends ClusterEvent {
  final String workerId;

  const WorkerRegistered({
    required super.id,
    required super.timestamp,
    required this.workerId,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'WorkerRegistered',
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'workerId': workerId,
      };
}

class WorkerUnregistered extends ClusterEvent {
  final String workerId;

  const WorkerUnregistered({
    required super.id,
    required super.timestamp,
    required this.workerId,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'WorkerUnregistered',
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'workerId': workerId,
      };
}

class HeartbeatReceived extends ClusterEvent {
  final String workerId;

  const HeartbeatReceived({
    required super.id,
    required super.timestamp,
    required this.workerId,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'HeartbeatReceived',
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'workerId': workerId,
      };
}

class JobSubmitted extends ClusterEvent {
  final String jobId;

  const JobSubmitted({
    required super.id,
    required super.timestamp,
    required this.jobId,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'JobSubmitted',
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'jobId': jobId,
      };
}

class JobDispatched extends ClusterEvent {
  final String jobId;
  final String workerId;

  const JobDispatched({
    required super.id,
    required super.timestamp,
    required this.jobId,
    required this.workerId,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'JobDispatched',
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'jobId': jobId,
        'workerId': workerId,
      };
}

class JobCompleted extends ClusterEvent {
  final String jobId;

  const JobCompleted({
    required super.id,
    required super.timestamp,
    required this.jobId,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'JobCompleted',
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'jobId': jobId,
      };
}

class LeaseAcquired extends ClusterEvent {
  final String leaseId;
  final String resourcePath;

  const LeaseAcquired({
    required super.id,
    required super.timestamp,
    required this.leaseId,
    required this.resourcePath,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'LeaseAcquired',
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'leaseId': leaseId,
        'resourcePath': resourcePath,
      };
}

class LeaseReleased extends ClusterEvent {
  final String leaseId;

  const LeaseReleased({
    required super.id,
    required super.timestamp,
    required this.leaseId,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'LeaseReleased',
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'leaseId': leaseId,
      };
}

class LeaseExpired extends ClusterEvent {
  final String leaseId;

  const LeaseExpired({
    required super.id,
    required super.timestamp,
    required this.leaseId,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'LeaseExpired',
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'leaseId': leaseId,
      };
}
