import '../models/ai_request.dart';
import '../models/execution_result.dart';

abstract class RuntimeEvent {
  final DateTime timestamp;
  final String eventId;

  RuntimeEvent({required this.timestamp, required this.eventId});
}

class RuntimeStarted extends RuntimeEvent {
  final AIRequest request;

  RuntimeStarted({
    required DateTime timestamp,
    required String eventId,
    required this.request,
  }) : super(timestamp: timestamp, eventId: eventId);
}

class RuntimeCompleted extends RuntimeEvent {
  final ExecutionResult result;

  RuntimeCompleted({
    required DateTime timestamp,
    required String eventId,
    required this.result,
  }) : super(timestamp: timestamp, eventId: eventId);
}

class ProviderSelected extends RuntimeEvent {
  final String providerName;
  final String modelName;

  ProviderSelected({
    required DateTime timestamp,
    required String eventId,
    required this.providerName,
    required this.modelName,
  }) : super(timestamp: timestamp, eventId: eventId);
}

class RetryAttempted extends RuntimeEvent {
  final int attempt;
  final String error;
  final Duration delay;

  RetryAttempted({
    required DateTime timestamp,
    required String eventId,
    required this.attempt,
    required this.error,
    required this.delay,
  }) : super(timestamp: timestamp, eventId: eventId);
}

class BudgetExceeded extends RuntimeEvent {
  final String modelName;
  final double cost;
  final double limit;

  BudgetExceeded({
    required DateTime timestamp,
    required String eventId,
    required this.modelName,
    required this.cost,
    required this.limit,
  }) : super(timestamp: timestamp, eventId: eventId);
}

class ExecutionFailed extends RuntimeEvent {
  final String error;
  final List<String> details;

  ExecutionFailed({
    required DateTime timestamp,
    required String eventId,
    required this.error,
    required this.details,
  }) : super(timestamp: timestamp, eventId: eventId);
}
