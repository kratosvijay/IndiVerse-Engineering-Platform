import 'execution_state.dart';

sealed class PlanEvent {
  final String planId;
  final String executionId;
  final DateTime timestamp;

  const PlanEvent({
    required this.planId,
    required this.executionId,
    required this.timestamp,
  });

  Map<String, dynamic> toJson();

  factory PlanEvent.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    final planId = json['planId'] as String;
    final executionId = json['executionId'] as String? ?? '';
    final timestamp = DateTime.parse(
      json['timestamp'] as String? ?? DateTime.now().toIso8601String(),
    );

    switch (type) {
      case 'plan_started':
        return PlanStartedEvent(
          planId: planId,
          executionId: executionId,
          timestamp: timestamp,
          session: ExecutionSession.fromJson(
              json['session'] as Map<String, dynamic>),
        );
      case 'plan_status_changed':
        return PlanStatusChangedEvent(
          planId: planId,
          executionId: executionId,
          timestamp: timestamp,
          status: PlanStatus.values.firstWhere((e) => e.name == json['status']),
        );
      case 'step_started':
        return StepStartedEvent(
          planId: planId,
          executionId: executionId,
          timestamp: timestamp,
          stepId: json['stepId'] as String,
        );
      case 'step_completed':
        return StepCompletedEvent(
          planId: planId,
          executionId: executionId,
          timestamp: timestamp,
          stepId: json['stepId'] as String,
          output: json['output'] as String?,
        );
      case 'step_failed':
        return StepFailedEvent(
          planId: planId,
          executionId: executionId,
          timestamp: timestamp,
          stepId: json['stepId'] as String,
          error: json['error'] as String?,
        );
      case 'step_skipped':
        return StepSkippedEvent(
          planId: planId,
          executionId: executionId,
          timestamp: timestamp,
          stepId: json['stepId'] as String,
        );
      case 'plan_completed':
        return PlanCompletedEvent(
          planId: planId,
          executionId: executionId,
          timestamp: timestamp,
          session: ExecutionSession.fromJson(
              json['session'] as Map<String, dynamic>),
        );
      default:
        throw Exception('Unknown PlanEvent type: $type');
    }
  }
}

class PlanStartedEvent extends PlanEvent {
  final ExecutionSession session;
  const PlanStartedEvent({
    required super.planId,
    required super.executionId,
    required super.timestamp,
    required this.session,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'plan_started',
        'planId': planId,
        'executionId': executionId,
        'timestamp': timestamp.toIso8601String(),
        'session': session.toJson(),
      };
}

class PlanStatusChangedEvent extends PlanEvent {
  final PlanStatus status;
  const PlanStatusChangedEvent({
    required super.planId,
    required super.executionId,
    required super.timestamp,
    required this.status,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'plan_status_changed',
        'planId': planId,
        'executionId': executionId,
        'timestamp': timestamp.toIso8601String(),
        'status': status.name,
      };
}

class StepStartedEvent extends PlanEvent {
  final String stepId;
  const StepStartedEvent({
    required super.planId,
    required super.executionId,
    required super.timestamp,
    required this.stepId,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'step_started',
        'planId': planId,
        'executionId': executionId,
        'timestamp': timestamp.toIso8601String(),
        'stepId': stepId,
      };
}

class StepCompletedEvent extends PlanEvent {
  final String stepId;
  final String? output;
  const StepCompletedEvent({
    required super.planId,
    required super.executionId,
    required super.timestamp,
    required this.stepId,
    this.output,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'step_completed',
        'planId': planId,
        'executionId': executionId,
        'timestamp': timestamp.toIso8601String(),
        'stepId': stepId,
        'output': output,
      };
}

class StepFailedEvent extends PlanEvent {
  final String stepId;
  final String? error;
  const StepFailedEvent({
    required super.planId,
    required super.executionId,
    required super.timestamp,
    required this.stepId,
    this.error,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'step_failed',
        'planId': planId,
        'executionId': executionId,
        'timestamp': timestamp.toIso8601String(),
        'stepId': stepId,
        'error': error,
      };
}

class StepSkippedEvent extends PlanEvent {
  final String stepId;
  const StepSkippedEvent({
    required super.planId,
    required super.executionId,
    required super.timestamp,
    required this.stepId,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'step_skipped',
        'planId': planId,
        'executionId': executionId,
        'timestamp': timestamp.toIso8601String(),
        'stepId': stepId,
      };
}

class PlanCompletedEvent extends PlanEvent {
  final ExecutionSession session;
  const PlanCompletedEvent({
    required super.planId,
    required super.executionId,
    required super.timestamp,
    required this.session,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'plan_completed',
        'planId': planId,
        'executionId': executionId,
        'timestamp': timestamp.toIso8601String(),
        'session': session.toJson(),
      };
}
