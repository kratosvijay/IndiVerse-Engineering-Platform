import 'package:indiverse_developer_platform/core/models/tool_call_models.dart';
import 'message_metadata.dart';

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

class AIModel {
  final String id;
  final String name;
  final String provider;
  final int contextWindow;
  final bool supportsVision;
  final bool supportsTools;
  final bool supportsReasoning;
  final bool supportsJsonMode;
  final bool supportsStreaming;

  const AIModel({
    required this.id,
    required this.name,
    required this.provider,
    required this.contextWindow,
    required this.supportsVision,
    required this.supportsTools,
    required this.supportsReasoning,
    required this.supportsJsonMode,
    required this.supportsStreaming,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'provider': provider,
    'contextWindow': contextWindow,
    'supportsVision': supportsVision,
    'supportsTools': supportsTools,
    'supportsReasoning': supportsReasoning,
    'supportsJsonMode': supportsJsonMode,
    'supportsStreaming': supportsStreaming,
  };

  factory AIModel.fromJson(Map<String, dynamic> json) => AIModel(
    id: json['id'] as String,
    name: json['name'] as String,
    provider: json['provider'] as String,
    contextWindow: json['contextWindow'] as int,
    supportsVision: json['supportsVision'] as bool? ?? false,
    supportsTools: json['supportsTools'] as bool? ?? false,
    supportsReasoning: json['supportsReasoning'] as bool? ?? false,
    supportsJsonMode: json['supportsJsonMode'] as bool? ?? false,
    supportsStreaming: json['supportsStreaming'] as bool? ?? false,
  );
}

enum AIProviderState {
  initializing,
  authenticating,
  ready,
  streaming,
  rateLimited,
  recovering,
  offline,
  failed,
}

class AIProviderMetrics {
  final int requestCount;
  final int successCount;
  final int failedCount;
  final int promptTokens;
  final int completionTokens;
  final int cacheHits;
  final int cacheMisses;
  final int cancelledRequests;
  final int retryCount;
  final Duration totalLatency;
  final Duration totalTtf;
  final Duration totalStreamDuration;
  final double tokensPerSecond;

  const AIProviderMetrics({
    required this.requestCount,
    required this.successCount,
    required this.failedCount,
    required this.promptTokens,
    required this.completionTokens,
    required this.cacheHits,
    required this.cacheMisses,
    required this.cancelledRequests,
    required this.retryCount,
    required this.totalLatency,
    required this.totalTtf,
    required this.totalStreamDuration,
    required this.tokensPerSecond,
  });

  factory AIProviderMetrics.fromJson(Map<String, dynamic> json) =>
      AIProviderMetrics(
        requestCount: json['requestCount'] as int? ?? 0,
        successCount: json['successCount'] as int? ?? 0,
        failedCount: json['failedCount'] as int? ?? 0,
        promptTokens: json['promptTokens'] as int? ?? 0,
        completionTokens: json['completionTokens'] as int? ?? 0,
        cacheHits: json['cacheHits'] as int? ?? 0,
        cacheMisses: json['cacheMisses'] as int? ?? 0,
        cancelledRequests: json['cancelledRequests'] as int? ?? 0,
        retryCount: json['retryCount'] as int? ?? 0,
        totalLatency: Duration(
          milliseconds: json['totalLatencyMs'] as int? ?? 0,
        ),
        totalTtf: Duration(milliseconds: json['totalTtfMs'] as int? ?? 0),
        totalStreamDuration: Duration(
          milliseconds: json['totalStreamDurationMs'] as int? ?? 0,
        ),
        tokensPerSecond: (json['tokensPerSecond'] as num? ?? 0.0).toDouble(),
      );
}

class AIProviderHealth {
  final AIProviderState state;
  final Duration averageLatency;
  final DateTime lastSuccessfulRequest;
  final int consecutiveFailures;

  const AIProviderHealth({
    required this.state,
    required this.averageLatency,
    required this.lastSuccessfulRequest,
    required this.consecutiveFailures,
  });

  factory AIProviderHealth.fromJson(Map<String, dynamic> json) =>
      AIProviderHealth(
        state: AIProviderState.values.firstWhere(
          (e) => e.name == json['state'],
          orElse: () => AIProviderState.ready,
        ),
        averageLatency: Duration(
          milliseconds: json['averageLatencyMs'] as int? ?? 0,
        ),
        lastSuccessfulRequest: DateTime.parse(
          json['lastSuccessfulRequest'] as String? ??
              DateTime.now().toIso8601String(),
        ),
        consecutiveFailures: json['consecutiveFailures'] as int? ?? 0,
      );
}

class AIProviderCapabilities {
  final bool chat;
  final bool streaming;
  final bool tools;
  final bool vision;
  final bool embeddings;
  final bool images;
  final bool reasoning;

  const AIProviderCapabilities({
    required this.chat,
    required this.streaming,
    required this.tools,
    required this.vision,
    required this.embeddings,
    required this.images,
    required this.reasoning,
  });

  factory AIProviderCapabilities.fromJson(Map<String, dynamic> json) =>
      AIProviderCapabilities(
        chat: json['chat'] as bool? ?? true,
        streaming: json['streaming'] as bool? ?? true,
        tools: json['tools'] as bool? ?? false,
        vision: json['vision'] as bool? ?? false,
        embeddings: json['embeddings'] as bool? ?? false,
        images: json['images'] as bool? ?? false,
        reasoning: json['reasoning'] as bool? ?? false,
      );
}

enum ChatRole { system, user, assistant, tool }

class ChatMessage {
  final ChatRole role;
  final String content;
  final String? name;
  final DateTime timestamp;
  final MessageMetadata? metadata;
  final String? reasoning;

  const ChatMessage({
    required this.role,
    required this.content,
    this.name,
    required this.timestamp,
    this.metadata,
    this.reasoning,
  });

  Map<String, dynamic> toJson() => {
    'role': role.name,
    'content': content,
    if (name != null) 'name': name,
    'timestamp': timestamp.toIso8601String(),
    if (metadata != null) 'metadata': metadata!.toJson(),
    if (reasoning != null) 'reasoning': reasoning,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    role: ChatRole.values.firstWhere((e) => e.name == json['role']),
    content: json['content'] as String,
    name: json['name'] as String?,
    timestamp: DateTime.parse(json['timestamp'] as String),
    metadata: json['metadata'] != null
        ? MessageMetadata.fromJson(json['metadata'] as Map<String, dynamic>)
        : null,
    reasoning: json['reasoning'] as String?,
  );
}

class ConversationSession {
  final String id;
  final String title;
  final String workspace;
  final String providerId;
  final String modelId;
  final List<ChatMessage> messages;
  final int estimatedTokens;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ConversationSession({
    required this.id,
    required this.title,
    required this.workspace,
    required this.providerId,
    required this.modelId,
    required this.messages,
    required this.estimatedTokens,
    required this.createdAt,
    required this.updatedAt,
  });

  ConversationSession copyWith({
    String? title,
    List<ChatMessage>? messages,
    int? estimatedTokens,
    DateTime? updatedAt,
  }) {
    return ConversationSession(
      id: id,
      title: title ?? this.title,
      workspace: workspace,
      providerId: providerId,
      modelId: modelId,
      messages: messages ?? this.messages,
      estimatedTokens: estimatedTokens ?? this.estimatedTokens,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'workspace': workspace,
    'providerId': providerId,
    'modelId': modelId,
    'messages': messages.map((m) => m.toJson()).toList(),
    'estimatedTokens': estimatedTokens,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory ConversationSession.fromJson(Map<String, dynamic> json) =>
      ConversationSession(
        id: json['id'] as String,
        title: json['title'] as String,
        workspace: json['workspace'] as String,
        providerId: json['providerId'] as String,
        modelId: json['modelId'] as String,
        messages: (json['messages'] as List)
            .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
            .toList(),
        estimatedTokens: json['estimatedTokens'] as int? ?? 0,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}

abstract class AIStreamEvent {
  final String requestId;
  final DateTime timestamp;

  const AIStreamEvent({required this.requestId, required this.timestamp});

  factory AIStreamEvent.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    final reqId = json['requestId'] as String? ?? '';
    final ts = DateTime.parse(
      json['timestamp'] as String? ?? DateTime.now().toIso8601String(),
    );

    switch (type) {
      case 'stage':
        return StageEvent(
          requestId: reqId,
          timestamp: ts,
          stage: RequestStage.values.firstWhere(
            (e) => e.name == json['stage'],
            orElse: () => RequestStage.preparing,
          ),
        );
      case 'token':
        return TokenChunkEvent(
          requestId: reqId,
          timestamp: ts,
          chunk: json['chunk'] as String? ?? '',
        );
      case 'reasoning':
        return ReasoningChunkEvent(
          requestId: reqId,
          timestamp: ts,
          reasoning: json['reasoning'] as String? ?? '',
        );
      case 'tool_call':
        return ToolCallEvent(
          requestId: reqId,
          timestamp: ts,
          toolId: json['toolId'] as String? ?? '',
          name: json['name'] as String? ?? '',
          arguments: Map<String, dynamic>.from(json['arguments'] as Map? ?? {}),
        );
      case 'tool_result':
        return ToolResultEvent(
          requestId: reqId,
          timestamp: ts,
          toolId: json['toolId'] as String? ?? '',
          result: json['result'] as String? ?? '',
        );
      case 'usage':
        return UsageEvent(
          requestId: reqId,
          timestamp: ts,
          promptTokens: json['promptTokens'] as int? ?? 0,
          completionTokens: json['completionTokens'] as int? ?? 0,
        );
      case 'completed':
        return CompletedEvent(
          requestId: reqId,
          timestamp: ts,
          fullText: json['fullText'] as String? ?? '',
          finishReason: FinishReason.values.firstWhere(
            (e) => e.name == json['finishReason'],
            orElse: () => FinishReason.stop,
          ),
        );
      case 'tool_permission_requested':
        return ToolPermissionRequestedEvent(
          requestId: reqId,
          timestamp: ts,
          toolCallId: json['toolCallId'] as String? ?? '',
          toolName: json['toolName'] as String? ?? '',
          arguments: Map<String, dynamic>.from(json['arguments'] as Map? ?? {}),
        );
      case 'tool_call_started':
        return ToolCallStartedEvent(
          requestId: reqId,
          timestamp: ts,
          toolCallId: json['toolCallId'] as String? ?? '',
          toolName: json['toolName'] as String? ?? '',
          arguments: Map<String, dynamic>.from(json['arguments'] as Map? ?? {}),
        );
      case 'tool_call_progress':
        return ToolCallProgressEvent(
          requestId: reqId,
          timestamp: ts,
          toolCallId: json['toolCallId'] as String? ?? '',
          message: json['message'] as String? ?? '',
        );
      case 'tool_call_completed':
        return ToolCallCompletedEvent(
          requestId: reqId,
          timestamp: ts,
          toolCallId: json['toolCallId'] as String? ?? '',
          result: ToolCallResult.fromJson(json['result'] as Map<String, dynamic>? ?? {}),
        );
      case 'tool_call_failed':
        return ToolCallFailedEvent(
          requestId: reqId,
          timestamp: ts,
          toolCallId: json['toolCallId'] as String? ?? '',
          code: json['code'] as String? ?? '',
          message: json['message'] as String? ?? '',
        );
      case 'error':
      default:
        return ErrorEvent(
          requestId: reqId,
          timestamp: ts,
          code: json['code'] as String? ?? 'ERROR',
          message: json['message'] as String? ?? 'Unknown error',
        );
    }
  }
}

class StageEvent extends AIStreamEvent {
  final RequestStage stage;
  const StageEvent({
    required super.requestId,
    required super.timestamp,
    required this.stage,
  });
}

class TokenChunkEvent extends AIStreamEvent {
  final String chunk;
  const TokenChunkEvent({
    required super.requestId,
    required super.timestamp,
    required this.chunk,
  });
}

class ReasoningChunkEvent extends AIStreamEvent {
  final String reasoning;
  const ReasoningChunkEvent({
    required super.requestId,
    required super.timestamp,
    required this.reasoning,
  });
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
}
