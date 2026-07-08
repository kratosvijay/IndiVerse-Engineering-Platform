import '../models/tool_call_models.dart';

enum RequestStage {
  preparing,
  gatheringContext,
  optimizingPrompt,
  waitingProvider,
  streaming,
  completed,
  cancelled,
  failed,
}

enum FinishReason {
  stop,
  length,
  cancelled,
  toolCall,
  error,
}

sealed class AIStreamEvent {
  final String requestId;
  final DateTime timestamp;

  const AIStreamEvent({
    required this.requestId,
    required this.timestamp,
  });

  Map<String, dynamic> toJson();
}

class TokenChunkEvent extends AIStreamEvent {
  final String chunk;

  const TokenChunkEvent({
    required super.requestId,
    required super.timestamp,
    required this.chunk,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'token',
        'requestId': requestId,
        'timestamp': timestamp.toIso8601String(),
        'chunk': chunk,
      };
}

class ReasoningChunkEvent extends AIStreamEvent {
  final String reasoning;

  const ReasoningChunkEvent({
    required super.requestId,
    required super.timestamp,
    required this.reasoning,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'reasoning',
        'requestId': requestId,
        'timestamp': timestamp.toIso8601String(),
        'reasoning': reasoning,
      };
}

class ToolCallEvent extends AIStreamEvent {
  final String toolId;
  final String name;
  final Map<String, dynamic> arguments;

  const ToolCallEvent({
    required super.requestId,
    required super.timestamp,
    required this.toolId,
    required this.name,
    required this.arguments,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'tool_call',
        'requestId': requestId,
        'timestamp': timestamp.toIso8601String(),
        'toolId': toolId,
        'name': name,
        'arguments': arguments,
      };
}

class ToolResultEvent extends AIStreamEvent {
  final String toolId;
  final String result;

  const ToolResultEvent({
    required super.requestId,
    required super.timestamp,
    required this.toolId,
    required this.result,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'tool_result',
        'requestId': requestId,
        'timestamp': timestamp.toIso8601String(),
        'toolId': toolId,
        'result': result,
      };
}

class UsageEvent extends AIStreamEvent {
  final int promptTokens;
  final int completionTokens;

  const UsageEvent({
    required super.requestId,
    required super.timestamp,
    required this.promptTokens,
    required this.completionTokens,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'usage',
        'requestId': requestId,
        'timestamp': timestamp.toIso8601String(),
        'promptTokens': promptTokens,
        'completionTokens': completionTokens,
      };
}

class StageEvent extends AIStreamEvent {
  final RequestStage stage;

  const StageEvent({
    required super.requestId,
    required super.timestamp,
    required this.stage,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'stage',
        'requestId': requestId,
        'timestamp': timestamp.toIso8601String(),
        'stage': stage.name,
      };
}

class CompletedEvent extends AIStreamEvent {
  final String fullText;
  final FinishReason finishReason;

  const CompletedEvent({
    required super.requestId,
    required super.timestamp,
    required this.fullText,
    this.finishReason = FinishReason.stop,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'completed',
        'requestId': requestId,
        'timestamp': timestamp.toIso8601String(),
        'fullText': fullText,
        'finishReason': finishReason.name,
      };
}

class ErrorEvent extends AIStreamEvent {
  final String code;
  final String message;

  const ErrorEvent({
    required super.requestId,
    required super.timestamp,
    required this.code,
    required this.message,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'error',
        'requestId': requestId,
        'timestamp': timestamp.toIso8601String(),
        'code': code,
        'message': message,
      };
}

class ToolPermissionRequestedEvent extends AIStreamEvent {
  final String toolCallId;
  final String toolName;
  final Map<String, dynamic> arguments;

  const ToolPermissionRequestedEvent({
    required super.requestId,
    required super.timestamp,
    required this.toolCallId,
    required this.toolName,
    required this.arguments,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'tool_permission_requested',
        'requestId': requestId,
        'timestamp': timestamp.toIso8601String(),
        'toolCallId': toolCallId,
        'toolName': toolName,
        'arguments': arguments,
      };
}

class ToolCallStartedEvent extends AIStreamEvent {
  final String toolCallId;
  final String toolName;
  final Map<String, dynamic> arguments;

  const ToolCallStartedEvent({
    required super.requestId,
    required super.timestamp,
    required this.toolCallId,
    required this.toolName,
    required this.arguments,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'tool_call_started',
        'requestId': requestId,
        'timestamp': timestamp.toIso8601String(),
        'toolCallId': toolCallId,
        'toolName': toolName,
        'arguments': arguments,
      };
}

class ToolCallProgressEvent extends AIStreamEvent {
  final String toolCallId;
  final String message;

  const ToolCallProgressEvent({
    required super.requestId,
    required super.timestamp,
    required this.toolCallId,
    required this.message,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'tool_call_progress',
        'requestId': requestId,
        'timestamp': timestamp.toIso8601String(),
        'toolCallId': toolCallId,
        'message': message,
      };
}

class ToolCallCompletedEvent extends AIStreamEvent {
  final String toolCallId;
  final ToolCallResult result;

  const ToolCallCompletedEvent({
    required super.requestId,
    required super.timestamp,
    required this.toolCallId,
    required this.result,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'tool_call_completed',
        'requestId': requestId,
        'timestamp': timestamp.toIso8601String(),
        'toolCallId': toolCallId,
        'result': result.toJson(),
      };
}

class ToolCallFailedEvent extends AIStreamEvent {
  final String toolCallId;
  final String code;
  final String message;

  const ToolCallFailedEvent({
    required super.requestId,
    required super.timestamp,
    required this.toolCallId,
    required this.code,
    required this.message,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'tool_call_failed',
        'requestId': requestId,
        'timestamp': timestamp.toIso8601String(),
        'toolCallId': toolCallId,
        'code': code,
        'message': message,
      };
}
