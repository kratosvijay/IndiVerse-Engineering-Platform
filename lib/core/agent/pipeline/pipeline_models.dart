enum DeploymentTarget { local, development, qa, staging, production }

enum PipelineStageStatus { pending, running, passed, failed, cancelled }

enum DeploymentStatus {
  planning,
  pendingApproval,
  deploying,
  canary,
  rollingOut,
  verifying,
  completed,
  failed,
  rolledBack
}

class PipelineStage {
  final String id;
  final String name;
  final PipelineStageStatus status;
  final Duration duration;

  const PipelineStage({
    required this.id,
    required this.name,
    required this.status,
    required this.duration,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'status': status.name,
        'durationMs': duration.inMilliseconds,
      };
}

class PipelineArtifact {
  final String id;
  final String name;
  final int sizeInBytes;
  final String downloadUrl;

  const PipelineArtifact({
    required this.id,
    required this.name,
    required this.sizeInBytes,
    required this.downloadUrl,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'sizeInBytes': sizeInBytes,
        'downloadUrl': downloadUrl,
      };
}

class PipelineLog {
  final String line;
  final DateTime timestamp;

  const PipelineLog({
    required this.line,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'line': line,
        'timestamp': timestamp.toIso8601String(),
      };
}

class HealthSnapshot {
  final double availability; // 0.0 to 1.0
  final double crashRate; // percentage
  final double errorRate; // percentage
  final double responseTimeMs;
  final double resourceUsage; // CPU/memory percentage
  final double healthScore; // derived 0.0 to 10.0
  final DateTime timestamp;

  const HealthSnapshot({
    required this.availability,
    required this.crashRate,
    required this.errorRate,
    required this.responseTimeMs,
    required this.resourceUsage,
    required this.healthScore,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'availability': availability,
        'crashRate': crashRate,
        'errorRate': errorRate,
        'responseTimeMs': responseTimeMs,
        'resourceUsage': resourceUsage,
        'healthScore': healthScore,
        'timestamp': timestamp.toIso8601String(),
      };
}

class PipelineMetrics {
  final int totalRuns;
  final int successfulRuns;
  final double successRate;
  final Duration averageDuration;

  const PipelineMetrics({
    required this.totalRuns,
    required this.successfulRuns,
    required this.successRate,
    required this.averageDuration,
  });

  Map<String, dynamic> toJson() => {
        'totalRuns': totalRuns,
        'successfulRuns': successfulRuns,
        'successRate': successRate,
        'averageDurationMs': averageDuration.inMilliseconds,
      };
}

class PipelineRun {
  final String id;
  final String pipelineId;
  final String commitHash;
  final List<PipelineStage> stages;
  final DateTime createdAt;
  final PipelineStageStatus status;

  const PipelineRun({
    required this.id,
    required this.pipelineId,
    required this.commitHash,
    required this.stages,
    required this.createdAt,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'pipelineId': pipelineId,
        'commitHash': commitHash,
        'stages': stages.map((s) => s.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'status': status.name,
      };
}

enum RollbackStepType {
  revertGitBranch,
  restoreDbSnapshot,
  notifySlack,
  switchLoadBalancer
}

class RollbackStep {
  final String id;
  final RollbackStepType type;
  final String target;
  final bool completed;

  const RollbackStep({
    required this.id,
    required this.type,
    required this.target,
    this.completed = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'target': target,
        'completed': completed,
      };
}

class RollbackPlan {
  final String id;
  final String deploymentId;
  final String targetRevision;
  final List<RollbackStep> steps;
  final DateTime createdAt;

  const RollbackPlan({
    required this.id,
    required this.deploymentId,
    required this.targetRevision,
    required this.steps,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'deploymentId': deploymentId,
        'targetRevision': targetRevision,
        'steps': steps.map((s) => s.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };
}

class DeploymentResult {
  final String id;
  final DeploymentTarget target;
  final DeploymentStatus status;
  final HealthSnapshot? healthSnapshot;
  final DateTime updatedAt;

  const DeploymentResult({
    required this.id,
    required this.target,
    required this.status,
    this.healthSnapshot,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'target': target.name,
        'status': status.name,
        'healthSnapshot': healthSnapshot?.toJson(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}

// Sealed Event Hierarchy
sealed class PipelineEvent {
  final String id;
  final DateTime timestamp;

  const PipelineEvent({
    required this.id,
    required this.timestamp,
  });

  Map<String, dynamic> toJson();
}

class PipelineStarted extends PipelineEvent {
  final String runId;

  const PipelineStarted({
    required super.id,
    required super.timestamp,
    required this.runId,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'PipelineStarted',
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'runId': runId,
      };
}

class StageStarted extends PipelineEvent {
  final String stageId;
  final String stageName;

  const StageStarted({
    required super.id,
    required super.timestamp,
    required this.stageId,
    required this.stageName,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'StageStarted',
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'stageId': stageId,
        'stageName': stageName,
      };
}

class StageCompleted extends PipelineEvent {
  final String stageId;
  final PipelineStageStatus status;

  const StageCompleted({
    required super.id,
    required super.timestamp,
    required this.stageId,
    required this.status,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'StageCompleted',
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'stageId': stageId,
        'status': status.name,
      };
}

class ApprovalRequested extends PipelineEvent {
  final String approvalId;
  final DeploymentTarget target;

  const ApprovalRequested({
    required super.id,
    required super.timestamp,
    required this.approvalId,
    required this.target,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'ApprovalRequested',
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'approvalId': approvalId,
        'target': target.name,
      };
}

class DeploymentStarted extends PipelineEvent {
  final String deploymentId;
  final DeploymentTarget target;

  const DeploymentStarted({
    required super.id,
    required super.timestamp,
    required this.deploymentId,
    required this.target,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'DeploymentStarted',
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'deploymentId': deploymentId,
        'target': target.name,
      };
}

class HealthWarning extends PipelineEvent {
  final String deploymentId;
  final double score;

  const HealthWarning({
    required super.id,
    required super.timestamp,
    required this.deploymentId,
    required this.score,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'HealthWarning',
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'deploymentId': deploymentId,
        'score': score,
      };
}

class RollbackStarted extends PipelineEvent {
  final String rollbackId;
  final String targetRevision;

  const RollbackStarted({
    required super.id,
    required super.timestamp,
    required this.rollbackId,
    required this.targetRevision,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'RollbackStarted',
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'rollbackId': rollbackId,
        'targetRevision': targetRevision,
      };
}

class RollbackCompleted extends PipelineEvent {
  final String rollbackId;

  const RollbackCompleted({
    required super.id,
    required super.timestamp,
    required this.rollbackId,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'RollbackCompleted',
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'rollbackId': rollbackId,
      };
}

class PipelineFinished extends PipelineEvent {
  final String runId;
  final PipelineStageStatus status;

  const PipelineFinished({
    required super.id,
    required super.timestamp,
    required this.runId,
    required this.status,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'PipelineFinished',
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'runId': runId,
        'status': status.name,
      };
}
