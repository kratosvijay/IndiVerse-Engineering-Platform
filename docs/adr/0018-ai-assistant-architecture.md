# ADR 0018 — AI Assistant Architecture

## Status
Approved

## Context
As IndiVerse Studio matures into an AI-native developer execution platform, it requires a robust, extensible, and vendor-agnostic AI subsystem. Rather than hardcoding prompts or tightly coupling a specific AI provider (such as Gemini or Claude) to chatbot UI elements, the AI layer must exist as a core platform subsystem alongside the workbench, editor, and language intelligence systems.

To avoid future regressions, ensure modularity, and handle high-throughput streaming responses, tool calling (MCP), context optimization, and model configurations, we require a formalized architectural framework.

## Decision
We enforce the **AI Assistant Architecture** separating capability abstractions, mutable execution managers, prompt template builders, and real-time stream event channels. All AI operations are presentation-agnostic and decoupled from specific LLM vendors.

### 1. Architectural Diagram

```
       [UI Presenters / Chat Panel / Inline Editor]
                           │
                           ▼
                      [AIService] (Orchestrates State, Session Synchronization)
                           │
      ┌────────────────────┼───────────────────┐
      ▼                    ▼                   ▼
[ConversationManager] [ContextEngine]   [PromptPipeline]
      │                    │                   │
      ▼                    ▼                   ▼
[ConversationStore]  [ContextProviders] [PromptOptimizer]
      │                    │                   │
      ▼                    ▼                   ▼
      └────────────────────┼───────────────────┘
                           │
                           ▼
                 [AIProviderRegistry]
                           │
                           ▼
                      [AIProvider] (Gemini, Claude, Ollama, Mock, etc.)
```

### 2. Capabilities, Models & Configurations

Providers are split into distinct functional capabilities so that implementations only conform to features they support.

```dart
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
}

abstract class AIProvider {
  String get id;
  String get name;
  AIProviderState get state;
  AIProviderMetrics get metrics;

  Future<void> initialize(AIProviderConfiguration config);
  Future<List<AIModel>> models();
}

abstract class AIChatProvider implements AIProvider {
  Future<Stream<AIStreamEvent>> chat(AIRequest request);
}
```

### 3. Immutable Conversations & Persistence

To support history management, undo actions, and reliable storage, conversation state remains fully immutable.

```dart
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
}

abstract class ConversationStore {
  Future<void> saveSession(ConversationSession session);
  Future<ConversationSession?> getSession(String id);
  Future<List<ConversationSession>> listSessions(String workspace);
  Future<void> deleteSession(String id);
}
```

### 4. Context Engine Plugin Framework

Context gathering uses an extensible plugin architecture to prevent rigid context-assembly logic.

```dart
class ContextRequest {
  final String workspace;
  final String? activeFilePath;
  final int maxTokens;

  const ContextRequest({
    required this.workspace,
    this.activeFilePath,
    required this.maxTokens,
  });
}

class ContextFragment {
  final String source;
  final String content;
  final int estimatedTokens;
  final int priority; // Higher numbers indicate higher priority

  const ContextFragment({
    required this.source,
    required this.content,
    required this.estimatedTokens,
    required this.priority,
  });
}

class ContextSnapshot {
  final List<ContextFragment> fragments;
  final DateTime timestamp;

  const ContextSnapshot({
    required this.fragments,
    required this.timestamp,
  });

  int get totalTokens => fragments.fold(0, (sum, f) => sum + f.estimatedTokens);
}

abstract class ContextProvider {
  String get id;
  Future<ContextFragment> resolve(ContextRequest request);
}
```

### 5. Structured Prompt Pipeline

Every prompt generation is processed in pipelines that separate context assembly, system templates, user prompt optimization (truncation/summarization), token limits checking, and provider calls.

```dart
class PromptTemplate {
  final String systemTemplate;
  final String userTemplate;

  const PromptTemplate({
    required this.systemTemplate,
    required this.userTemplate,
  });
}

class PromptPackage {
  final String systemPrompt;
  final String userPrompt;
  final List<ContextFragment> fragments;
  final int estimatedTokens;

  const PromptPackage({
    required this.systemPrompt,
    required this.userPrompt,
    required this.fragments,
    required this.estimatedTokens,
  });
}

class AIRequest {
  final ConversationSession session;
  final ContextSnapshot context;
  final PromptPackage promptPackage;
  final CancellationToken token;

  const AIRequest({
    required this.session,
    required this.context,
    required this.promptPackage,
    required this.token,
  });
}
```

### 6. Sealed Stream Event Hierarchy

All streaming operations output structured event types rather than raw strings to handle status codes, reasoning chunks, usage metrics, tool calls, and error handling.

```dart
sealed class AIStreamEvent {
  final String requestId;
  final DateTime timestamp;

  const AIStreamEvent({
    required this.requestId,
    required this.timestamp,
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

  const CompletedEvent({
    required super.requestId,
    required super.timestamp,
    required this.fullText,
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
```

### 7. Extensible Tool Registry (Reserving Interface)

```dart
class ToolInvocation {
  final String toolId;
  final Map<String, dynamic> arguments;

  const ToolInvocation({
    required this.toolId,
    required this.arguments,
  });
}

class ToolResult {
  final String result;
  final bool success;

  const ToolResult({
    required this.result,
    required this.success,
  });
}

abstract class AITool {
  String get id;
  String get description;
  Map<String, dynamic> get schema; // JSON Schema parameter specifications

  Future<ToolResult> execute(ToolInvocation invocation);
}
```

## Implications
- Switch between providers (e.g. cloud Gemini to local Ollama) is completely handled by the registry capabilities checklist.
- Unified prompt building and prompt optimization pipelines prevent token overflows by automatically pruning lower-priority context fragments.
- Subsystem events remain completely structured enabling tool invocation chunk merges at the UI layer.
