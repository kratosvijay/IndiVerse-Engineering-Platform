sealed class AgentRuntimeEvent {
  final String executionId;
  final String goalId;
  final DateTime timestamp;

  const AgentRuntimeEvent({
    required this.executionId,
    required this.goalId,
    required this.timestamp,
  });

  Map<String, dynamic> toJson();
}

class HeartbeatEvent extends AgentRuntimeEvent {
  final String? activeStepId;
  final double progress;
  final String statusMessage;

  const HeartbeatEvent({
    required super.executionId,
    required super.goalId,
    required super.timestamp,
    this.activeStepId,
    required this.progress,
    required this.statusMessage,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'heartbeat',
        'executionId': executionId,
        'goalId': goalId,
        'timestamp': timestamp.toIso8601String(),
        'activeStepId': activeStepId,
        'progress': progress,
        'statusMessage': statusMessage,
      };
}

class StepStartedEvent extends AgentRuntimeEvent {
  final String stepId;

  const StepStartedEvent({
    required super.executionId,
    required super.goalId,
    required super.timestamp,
    required this.stepId,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'step_started',
        'executionId': executionId,
        'goalId': goalId,
        'timestamp': timestamp.toIso8601String(),
        'stepId': stepId,
      };
}

class StepCompletedEvent extends AgentRuntimeEvent {
  final String stepId;
  final String? output;

  const StepCompletedEvent({
    required super.executionId,
    required super.goalId,
    required super.timestamp,
    required this.stepId,
    this.output,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'step_completed',
        'executionId': executionId,
        'goalId': goalId,
        'timestamp': timestamp.toIso8601String(),
        'stepId': stepId,
        'output': output,
      };
}

class StepRetryEvent extends AgentRuntimeEvent {
  final String stepId;
  final int retryCount;
  final String? error;

  const StepRetryEvent({
    required super.executionId,
    required super.goalId,
    required super.timestamp,
    required this.stepId,
    required this.retryCount,
    this.error,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'step_retry',
        'executionId': executionId,
        'goalId': goalId,
        'timestamp': timestamp.toIso8601String(),
        'stepId': stepId,
        'retryCount': retryCount,
        'error': error,
      };
}

class PlanModifiedEvent extends AgentRuntimeEvent {
  final String reasoning;
  final List<String> insertedStepIds;
  final List<String> replacementStepIds;

  const PlanModifiedEvent({
    required super.executionId,
    required super.goalId,
    required super.timestamp,
    required this.reasoning,
    this.insertedStepIds = const [],
    this.replacementStepIds = const [],
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'plan_modified',
        'executionId': executionId,
        'goalId': goalId,
        'timestamp': timestamp.toIso8601String(),
        'reasoning': reasoning,
        'insertedStepIds': insertedStepIds,
        'replacementStepIds': replacementStepIds,
      };
}

class GoalCompletedEvent extends AgentRuntimeEvent {
  final double progress;

  const GoalCompletedEvent({
    required super.executionId,
    required super.goalId,
    required super.timestamp,
    required this.progress,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'goal_completed',
        'executionId': executionId,
        'goalId': goalId,
        'timestamp': timestamp.toIso8601String(),
        'progress': progress,
      };
}

class ExecutionCancelledEvent extends AgentRuntimeEvent {
  const ExecutionCancelledEvent({
    required super.executionId,
    required super.goalId,
    required super.timestamp,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'execution_cancelled',
        'executionId': executionId,
        'goalId': goalId,
        'timestamp': timestamp.toIso8601String(),
      };
}

class AgentRegisteredEvent extends AgentRuntimeEvent {
  final String agentId;
  final String role;

  const AgentRegisteredEvent({
    required super.executionId,
    required super.goalId,
    required super.timestamp,
    required this.agentId,
    required this.role,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'agent_registered',
        'executionId': executionId,
        'goalId': goalId,
        'timestamp': timestamp.toIso8601String(),
        'agentId': agentId,
        'role': role,
      };
}

class AgentStartedEvent extends AgentRuntimeEvent {
  final String agentId;

  const AgentStartedEvent({
    required super.executionId,
    required super.goalId,
    required super.timestamp,
    required this.agentId,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'agent_started',
        'executionId': executionId,
        'goalId': goalId,
        'timestamp': timestamp.toIso8601String(),
        'agentId': agentId,
      };
}

class AgentStoppedEvent extends AgentRuntimeEvent {
  final String agentId;
  final bool success;

  const AgentStoppedEvent({
    required super.executionId,
    required super.goalId,
    required super.timestamp,
    required this.agentId,
    required this.success,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'agent_stopped',
        'executionId': executionId,
        'goalId': goalId,
        'timestamp': timestamp.toIso8601String(),
        'agentId': agentId,
        'success': success,
      };
}

class MessageSentEvent extends AgentRuntimeEvent {
  final String senderId;
  final String recipientId;

  const MessageSentEvent({
    required super.executionId,
    required super.goalId,
    required super.timestamp,
    required this.senderId,
    required this.recipientId,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'message_sent',
        'executionId': executionId,
        'goalId': goalId,
        'timestamp': timestamp.toIso8601String(),
        'senderId': senderId,
        'recipientId': recipientId,
      };
}

class ArtifactPublishedEvent extends AgentRuntimeEvent {
  final String artifactId;

  const ArtifactPublishedEvent({
    required super.executionId,
    required super.goalId,
    required super.timestamp,
    required this.artifactId,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'artifact_published',
        'executionId': executionId,
        'goalId': goalId,
        'timestamp': timestamp.toIso8601String(),
        'artifactId': artifactId,
      };
}

class AgentSpawnedEvent extends AgentRuntimeEvent {
  final String agentId;
  final String role;

  const AgentSpawnedEvent({
    required super.executionId,
    required super.goalId,
    required super.timestamp,
    required this.agentId,
    required this.role,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'agent_spawned',
        'executionId': executionId,
        'goalId': goalId,
        'timestamp': timestamp.toIso8601String(),
        'agentId': agentId,
        'role': role,
      };
}

class TaskAssignedEvent extends AgentRuntimeEvent {
  final String taskId;
  final String agentId;

  const TaskAssignedEvent({
    required super.executionId,
    required super.goalId,
    required super.timestamp,
    required this.taskId,
    required this.agentId,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'task_assigned',
        'executionId': executionId,
        'goalId': goalId,
        'timestamp': timestamp.toIso8601String(),
        'taskId': taskId,
        'agentId': agentId,
      };
}

class TaskCompletedEvent extends AgentRuntimeEvent {
  final String taskId;
  final bool success;

  const TaskCompletedEvent({
    required super.executionId,
    required super.goalId,
    required super.timestamp,
    required this.taskId,
    required this.success,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'task_completed',
        'executionId': executionId,
        'goalId': goalId,
        'timestamp': timestamp.toIso8601String(),
        'taskId': taskId,
        'success': success,
      };
}

class ConflictDetectedEvent extends AgentRuntimeEvent {
  final List<String> filePaths;

  const ConflictDetectedEvent({
    required super.executionId,
    required super.goalId,
    required super.timestamp,
    required this.filePaths,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'conflict_detected',
        'executionId': executionId,
        'goalId': goalId,
        'timestamp': timestamp.toIso8601String(),
        'filePaths': filePaths,
      };
}

class MergeCompletedEvent extends AgentRuntimeEvent {
  final List<String> filePaths;

  const MergeCompletedEvent({
    required super.executionId,
    required super.goalId,
    required super.timestamp,
    required this.filePaths,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'merge_completed',
        'executionId': executionId,
        'goalId': goalId,
        'timestamp': timestamp.toIso8601String(),
        'filePaths': filePaths,
      };
}

class CoordinatorFinishedEvent extends AgentRuntimeEvent {
  final bool success;

  const CoordinatorFinishedEvent({
    required super.executionId,
    required super.goalId,
    required super.timestamp,
    required this.success,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'coordinator_finished',
        'executionId': executionId,
        'goalId': goalId,
        'timestamp': timestamp.toIso8601String(),
        'success': success,
      };
}
