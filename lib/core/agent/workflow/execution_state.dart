import 'task_graph.dart';

enum StepStatus { pending, running, completed, failed, skipped }

class StepExecutionState {
  final String stepId;
  final StepStatus status;
  final String? output;
  final String? error;
  final int retryCount;

  const StepExecutionState({
    required this.stepId,
    this.status = StepStatus.pending,
    this.output,
    this.error,
    this.retryCount = 0,
  });

  StepExecutionState copyWith({
    StepStatus? status,
    String? output,
    String? error,
    int? retryCount,
  }) =>
      StepExecutionState(
        stepId: stepId,
        status: status ?? this.status,
        output: output ?? this.output,
        error: error ?? this.error,
        retryCount: retryCount ?? this.retryCount,
      );

  Map<String, dynamic> toJson() => {
        'stepId': stepId,
        'status': status.name,
        'output': output,
        'error': error,
        'retryCount': retryCount,
      };

  factory StepExecutionState.fromJson(Map<String, dynamic> json) =>
      StepExecutionState(
        stepId: json['stepId'] as String,
        status: StepStatus.values.firstWhere((e) => e.name == json['status']),
        output: json['output'] as String?,
        error: json['error'] as String?,
        retryCount: json['retryCount'] as int? ?? 0,
      );
}

enum PlanStatus {
  planning,
  ready,
  running,
  paused,
  waitingPermission,
  waitingUser,
  failed,
  cancelled,
  completed,
}

class ExecutionSession {
  final String executionId;
  final String planId;
  final TaskGraph graph;
  final PlanStatus status;
  final Map<String, StepExecutionState> stepStates;
  final double progress;
  final DateTime startedAt;
  final DateTime? completedAt;

  const ExecutionSession({
    required this.executionId,
    required this.planId,
    required this.graph,
    this.status = PlanStatus.ready,
    required this.stepStates,
    this.progress = 0.0,
    required this.startedAt,
    this.completedAt,
  });

  ExecutionSession copyWith({
    PlanStatus? status,
    Map<String, StepExecutionState>? stepStates,
    double? progress,
    DateTime? completedAt,
  }) =>
      ExecutionSession(
        executionId: executionId,
        planId: planId,
        graph: graph,
        status: status ?? this.status,
        stepStates: stepStates ?? this.stepStates,
        progress: progress ?? this.progress,
        startedAt: startedAt,
        completedAt: completedAt ?? this.completedAt,
      );

  Map<String, dynamic> toJson() => {
        'executionId': executionId,
        'planId': planId,
        'graph': graph.toJson(),
        'status': status.name,
        'stepStates': stepStates.map((k, v) => MapEntry(k, v.toJson())),
        'progress': progress,
        'startedAt': startedAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
      };

  factory ExecutionSession.fromJson(Map<String, dynamic> json) {
    final graph = TaskGraph.fromJson(json['graph'] as Map<String, dynamic>);
    final stepStatesMap = (json['stepStates'] as Map).map(
      (k, v) => MapEntry(
        k as String,
        StepExecutionState.fromJson(v as Map<String, dynamic>),
      ),
    );

    return ExecutionSession(
      executionId: json['executionId'] as String,
      planId: json['planId'] as String,
      graph: graph,
      status: PlanStatus.values.firstWhere((e) => e.name == json['status']),
      stepStates: stepStatesMap,
      progress: (json['progress'] as num? ?? 0.0).toDouble(),
      startedAt: DateTime.parse(json['startedAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }
}
