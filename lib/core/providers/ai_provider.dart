import 'dart:async';
import '../prompt/prompt_pipeline.dart';
import 'ai_stream_events.dart';

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

class AIProviderConfiguration {
  final String endpoint;
  final String apiKey;
  final Duration timeout;
  final bool enabled;
  final AIModel defaultModel;

  const AIProviderConfiguration({
    required this.endpoint,
    required this.apiKey,
    required this.timeout,
    required this.enabled,
    required this.defaultModel,
  });
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
  int requestCount = 0;
  int successCount = 0;
  int failedCount = 0;
  int promptTokens = 0;
  int completionTokens = 0;
  int cacheHits = 0;
  int cacheMisses = 0;
  int cancelledRequests = 0;
  int retryCount = 0;
  Duration totalLatency = Duration.zero;
  Duration totalTtf = Duration.zero; // Time to first token
  Duration totalStreamDuration = Duration.zero;

  double get tokensPerSecond => totalStreamDuration.inMilliseconds == 0
      ? 0.0
      : (completionTokens / (totalStreamDuration.inMilliseconds / 1000.0));

  Duration get averageLatency =>
      requestCount == 0 ? Duration.zero : totalLatency ~/ requestCount;

  Map<String, dynamic> toJson() => {
        'requestCount': requestCount,
        'successCount': successCount,
        'failedCount': failedCount,
        'promptTokens': promptTokens,
        'completionTokens': completionTokens,
        'cacheHits': cacheHits,
        'cacheMisses': cacheMisses,
        'cancelledRequests': cancelledRequests,
        'retryCount': retryCount,
        'totalLatencyMs': totalLatency.inMilliseconds,
        'totalTtfMs': totalTtf.inMilliseconds,
        'totalStreamDurationMs': totalStreamDuration.inMilliseconds,
        'tokensPerSecond': tokensPerSecond,
      };
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

  Map<String, dynamic> toJson() => {
        'state': state.name,
        'averageLatencyMs': averageLatency.inMilliseconds,
        'lastSuccessfulRequest': lastSuccessfulRequest.toIso8601String(),
        'consecutiveFailures': consecutiveFailures,
      };
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
    this.chat = true,
    this.streaming = true,
    this.tools = false,
    this.vision = false,
    this.embeddings = false,
    this.images = false,
    this.reasoning = false,
  });

  Map<String, dynamic> toJson() => {
        'chat': chat,
        'streaming': streaming,
        'tools': tools,
        'vision': vision,
        'embeddings': embeddings,
        'images': images,
        'reasoning': reasoning,
      };
}

abstract class AIProvider {
  String get id;
  String get name;
  int get priority;
  AIProviderState get state;
  AIProviderMetrics get metrics;
  AIProviderCapabilities get capabilities;

  Future<void> initialize(AIProviderConfiguration config);
  Future<List<AIModel>> models();
  AIProviderHealth getHealth();
}

abstract class AIChatProvider implements AIProvider {
  Future<Stream<AIStreamEvent>> chat(AIRequest request);
}

enum ChatRole {
  system,
  user,
  assistant,
  tool,
}

class ChatMessage {
  final ChatRole role;
  final String content;
  final String? name;
  final DateTime timestamp;

  const ChatMessage({
    required this.role,
    required this.content,
    this.name,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'role': role.name,
        'content': content,
        if (name != null) 'name': name,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        role: ChatRole.values.firstWhere((e) => e.name == json['role']),
        content: json['content'] as String,
        name: json['name'] as String?,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}
