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

class CompletedEvent extends AIStreamEvent {
  final String fullText;

  const CompletedEvent({
    required super.requestId,
    required super.timestamp,
    required this.fullText,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'completed',
        'requestId': requestId,
        'timestamp': timestamp.toIso8601String(),
        'fullText': fullText,
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
