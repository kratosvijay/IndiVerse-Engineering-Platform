import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/services/ai_service.dart';
import '../../../models/ai_models.dart';
import 'package:indiverse_developer_platform/core/models/tool_call_models.dart';
import '../../../models/request_metrics.dart';
import '../../../models/message_metadata.dart';
import 'chat_session_state.dart';

String generateAutoTitle(String text) {
  var cleaned = text
      .replaceAll(RegExp(r'[*_#`~\[\]\(\)]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  // Strip leading punctuation/markdown
  cleaned = cleaned.replaceFirst(RegExp(r'^[^a-zA-Z0-9]+'), '').trim();

  // Also remove colon if it was after the first word (like Question:)
  cleaned = cleaned.replaceAll(RegExp(r':\s*'), ' ');

  // Strip trailing punctuation
  cleaned = cleaned.replaceFirst(RegExp(r'[^a-zA-Z0-9]+$'), '').trim();

  if (cleaned.length <= 50) {
    return cleaned;
  }

  // Find the last space before the 50-character limit
  var truncated = cleaned.substring(0, 50);
  final lastSpace = truncated.lastIndexOf(' ');
  if (lastSpace > 0) {
    truncated = truncated.substring(0, lastSpace);
  }

  // Strip trailing punctuation from truncated
  truncated = truncated.replaceFirst(RegExp(r'[^a-zA-Z0-9]+$'), '').trim();

  return truncated;
}

class ChatController extends ChangeNotifier {
  final AIService aiService;
  final String workspace;

  ChatSessionState _state = const ChatSessionState();
  ChatSessionState get state => _state;

  final List<ConversationSession> _historyList = [];
  List<ConversationSession> get historyList => _historyList;

  // Active assistant message streamed chunk notifier (only this repaints during streaming)
  final ValueNotifier<ChatMessage?> activeStreamedMessage =
      ValueNotifier<ChatMessage?>(null);

  StreamSubscription<AIStreamEvent>? _streamSubscription;
  String? _currentRequestId;

  final Map<String, RequestMetrics> _requestMetricsMap = {};
  Map<String, RequestMetrics> get requestMetricsMap => _requestMetricsMap;

  final Map<String, String> _drafts = {};

  ChatController({required this.aiService, required this.workspace});

  Future<void> initialize() async {
    await fetchProvidersAndModels();
    await createNewSession("New Conversation");
  }

  void updateDraft(String text) {
    if (_state.session != null) {
      _drafts[_state.session!.id] = text;
    }
  }

  String getDraft(String sessionId) {
    return _drafts[sessionId] ?? '';
  }

  Future<void> fetchProvidersAndModels() async {
    try {
      final providers = await aiService.getProviders();
      final models = await aiService.getModels();

      String? defaultProvider;
      String? defaultModel;

      if (providers.isNotEmpty) {
        defaultProvider = providers.first['id'] as String?;
      }
      if (models.isNotEmpty) {
        defaultModel = models.first.id;
      }

      _state = _state.copyWith(
        activeProviderId: defaultProvider,
        activeModelId: defaultModel,
      );
      notifyListeners();
    } catch (_) {}
  }

  Future<void> createNewSession(String title) async {
    final now = DateTime.now();
    final newSession = ConversationSession(
      id: 'sess-${now.millisecondsSinceEpoch}',
      title: title,
      workspace: workspace,
      providerId: _state.activeProviderId ?? 'mock-ai',
      modelId: _state.activeModelId ?? 'mock-pro',
      messages: const [],
      estimatedTokens: 0,
      createdAt: now,
      updatedAt: now,
    );

    _historyList.insert(0, newSession);
    _state = _state.copyWith(
      session: newSession,
      messages: const [],
      streamState: ChatStreamState.idle,
      requestStage: null,
      clearError: true,
    );
    activeStreamedMessage.value = null;
    notifyListeners();
  }

  void switchSession(ConversationSession target) {
    _state = _state.copyWith(
      session: target,
      messages: target.messages,
      streamState: ChatStreamState.idle,
      requestStage: null,
      activeProviderId: target.providerId,
      activeModelId: target.modelId,
      clearError: true,
    );
    activeStreamedMessage.value = null;
    notifyListeners();
  }

  void selectProvider(String providerId) {
    _state = _state.copyWith(activeProviderId: providerId);
    if (_state.session != null) {
      final updated = _state.session!.copyWith(updatedAt: DateTime.now());
      _updateHistorySession(updated);
    }
    notifyListeners();
  }

  void selectModel(String modelId) {
    _state = _state.copyWith(activeModelId: modelId);
    if (_state.session != null) {
      final updated = _state.session!.copyWith(updatedAt: DateTime.now());
      _updateHistorySession(updated);
    }
    notifyListeners();
  }

  Future<void> sendPrompt(String promptText) async {
    final trimmed = promptText.trim();
    if (trimmed.isEmpty || _state.streamState != ChatStreamState.idle) return;

    // 1. Append user message
    final userMsg = ChatMessage(
      role: ChatRole.user,
      content: trimmed,
      timestamp: DateTime.now(),
    );

    var currentSession = _state.session;
    if (currentSession == null) return;

    final updatedMessages = List<ChatMessage>.from(_state.messages)
      ..add(userMsg);
    currentSession = currentSession.copyWith(
      messages: updatedMessages,
      title: currentSession.messages.isEmpty ? generateAutoTitle(trimmed) : currentSession.title,
      updatedAt: DateTime.now(),
    );

    _updateHistorySession(currentSession);
    _state = _state.copyWith(
      session: currentSession,
      messages: updatedMessages,
      streamState: ChatStreamState.preparing,
      requestStage: RequestStage.preparing,
      clearError: true,
      toolCalls: const [],
    );
    activeStreamedMessage.value = null;
    notifyListeners();

    // Yield control to the microtask queue so the UI has a chance to render the preparing state
    await Future.microtask(() {});

    // Ensure session hasn't been changed/cancelled during yield
    if (_state.session?.id != currentSession.id) return;

    // 2. Start Stream
    final reqId = 'req-${DateTime.now().millisecondsSinceEpoch}';
    _currentRequestId = reqId;

    _requestMetricsMap[reqId] = RequestMetrics(
      requestId: reqId,
      started: DateTime.now(),
    );

    _state = _state.copyWith(
      streamState: ChatStreamState.waitingFirstToken,
      requestStage: RequestStage.waitingProvider,
      toolCalls: const [],
    );
    notifyListeners();

    final stream = aiService.chatStream(
      session: currentSession,
      requestId: reqId,
    );

    String accumulatedText = '';
    String accumulatedReasoning = '';
    int? finalPromptTokens;
    int? finalCompletionTokens;

    activeStreamedMessage.value = ChatMessage(
      role: ChatRole.assistant,
      content: '',
      timestamp: DateTime.now(),
    );

    _streamSubscription = stream.listen(
      (event) {
        if (event is StageEvent) {
          _state = _state.copyWith(
            requestStage: event.stage,
          );
          if (event.stage == RequestStage.streaming) {
            _state = _state.copyWith(streamState: ChatStreamState.streaming);
          }
          notifyListeners();
        }

        if (event is TokenChunkEvent) {
          final currentMetrics = _requestMetricsMap[reqId];
          if (currentMetrics != null && currentMetrics.firstToken == null) {
            _requestMetricsMap[reqId] = currentMetrics.copyWith(
              firstToken: DateTime.now(),
            );
          }

          accumulatedText += event.chunk;
          activeStreamedMessage.value = ChatMessage(
            role: ChatRole.assistant,
            content: accumulatedText,
            reasoning: accumulatedReasoning.isNotEmpty ? accumulatedReasoning : null,
            timestamp: DateTime.now(),
          );
        } else if (event is ReasoningChunkEvent) {
          final currentMetrics = _requestMetricsMap[reqId];
          if (currentMetrics != null && currentMetrics.firstToken == null) {
            _requestMetricsMap[reqId] = currentMetrics.copyWith(
              firstToken: DateTime.now(),
            );
          }

          accumulatedReasoning += event.reasoning;
          activeStreamedMessage.value = ChatMessage(
            role: ChatRole.assistant,
            content: accumulatedText,
            reasoning: accumulatedReasoning,
            timestamp: DateTime.now(),
          );
        } else if (event is ToolPermissionRequestedEvent) {
          final newCall = ToolCallState(
            toolCallId: event.toolCallId,
            toolName: event.toolName,
            arguments: event.arguments,
            status: ToolCallStatus.pendingPermission,
          );
          final updated = List<ToolCallState>.from(_state.toolCalls)..add(newCall);
          _state = _state.copyWith(toolCalls: updated);
          notifyListeners();
        } else if (event is ToolCallStartedEvent) {
          final updated = _state.toolCalls.map((t) {
            if (t.toolCallId == event.toolCallId) {
              return t.copyWith(status: ToolCallStatus.running);
            }
            return t;
          }).toList();
          if (!updated.any((t) => t.toolCallId == event.toolCallId)) {
            updated.add(ToolCallState(
              toolCallId: event.toolCallId,
              toolName: event.toolName,
              arguments: event.arguments,
              status: ToolCallStatus.running,
            ));
          }
          _state = _state.copyWith(toolCalls: updated);
          notifyListeners();
        } else if (event is ToolCallProgressEvent) {
          final updated = _state.toolCalls.map((t) {
            if (t.toolCallId == event.toolCallId) {
              return t.copyWith(progressMessage: event.message);
            }
            return t;
          }).toList();
          _state = _state.copyWith(toolCalls: updated);
          notifyListeners();
        } else if (event is ToolCallCompletedEvent) {
          final updated = _state.toolCalls.map((t) {
            if (t.toolCallId == event.toolCallId) {
              return t.copyWith(
                status: ToolCallStatus.completed,
                result: event.result,
              );
            }
            return t;
          }).toList();
          _state = _state.copyWith(toolCalls: updated);
          notifyListeners();
        } else if (event is ToolCallFailedEvent) {
          final updated = _state.toolCalls.map((t) {
            if (t.toolCallId == event.toolCallId) {
              return t.copyWith(
                status: ToolCallStatus.failed,
                errorMessage: '${event.code}: ${event.message}',
              );
            }
            return t;
          }).toList();
          _state = _state.copyWith(toolCalls: updated);
          notifyListeners();
        } else if (event is UsageEvent) {
          finalPromptTokens = event.promptTokens;
          finalCompletionTokens = event.completionTokens;
        } else if (event is CompletedEvent) {
          accumulatedText = event.fullText;
          _state = _state.copyWith(
            requestStage: RequestStage.completed,
          );
        } else if (event is ErrorEvent) {
          final errorMetrics = _requestMetricsMap[reqId]?.copyWith(
            completed: DateTime.now(),
          );
          if (errorMetrics != null) {
            _requestMetricsMap[reqId] = errorMetrics;
          }
          _state = _state.copyWith(
            streamState: ChatStreamState.failed,
            requestStage: RequestStage.failed,
            error: '${event.code}: ${event.message}',
          );
          activeStreamedMessage.value = null;
          notifyListeners();

          Future.microtask(() {
            _state = _state.copyWith(streamState: ChatStreamState.idle);
            notifyListeners();
          });
        }
      },
      onError: (err) {
        final errorMetrics = _requestMetricsMap[reqId]?.copyWith(
          completed: DateTime.now(),
        );
        if (errorMetrics != null) {
          _requestMetricsMap[reqId] = errorMetrics;
        }
        _state = _state.copyWith(
          streamState: ChatStreamState.failed,
          requestStage: RequestStage.failed,
          error: err.toString(),
        );
        activeStreamedMessage.value = null;
        notifyListeners();

        Future.microtask(() {
          _state = _state.copyWith(streamState: ChatStreamState.idle);
          notifyListeners();
        });
      },
      onDone: () {
        final currentMetrics = _requestMetricsMap[reqId];
        final completedMetrics = currentMetrics?.copyWith(
          completed: DateTime.now(),
        );
        if (completedMetrics != null) {
          _requestMetricsMap[reqId] = completedMetrics;
        }

        if (_state.streamState == ChatStreamState.streaming ||
            _state.streamState == ChatStreamState.waitingFirstToken ||
            _state.streamState == ChatStreamState.preparing ||
            _state.streamState == ChatStreamState.finishing) {
          _state = _state.copyWith(
            streamState: ChatStreamState.finishing,
            requestStage: RequestStage.completed,
          );
          notifyListeners();

          final metadata = MessageMetadata(
            providerId: _state.activeProviderId,
            modelId: _state.activeModelId,
            promptTokens: finalPromptTokens,
            completionTokens: finalCompletionTokens,
            latencyMs: completedMetrics?.latencyMs,
            ttftMs: completedMetrics?.ttftMs,
            streamDurationMs: completedMetrics?.streamDurationMs,
            generatedAt: DateTime.now(),
          );

          final finalMsg = ChatMessage(
            role: ChatRole.assistant,
            content: accumulatedText.trim(),
            reasoning: accumulatedReasoning.isNotEmpty ? accumulatedReasoning.trim() : null,
            timestamp: DateTime.now(),
            metadata: metadata,
          );

          final finishedMessages = List<ChatMessage>.from(_state.messages)
            ..add(finalMsg);
          final finalSession = _state.session!.copyWith(
            messages: finishedMessages,
            updatedAt: DateTime.now(),
          );

          _updateHistorySession(finalSession);
          _state = _state.copyWith(
            session: finalSession,
            messages: finishedMessages,
            streamState: ChatStreamState.completed,
          );
          activeStreamedMessage.value = null;
          notifyListeners();
        }

        // Return to idle state after completion
        Future.microtask(() {
          _state = _state.copyWith(streamState: ChatStreamState.idle);
          notifyListeners();
        });
        _currentRequestId = null;
      },
    );
  }

  Future<void> stopGeneration() async {
    if (_state.streamState == ChatStreamState.idle) return;

    _state = _state.copyWith(
      streamState: ChatStreamState.stopping,
      requestStage: RequestStage.cancelled,
    );
    notifyListeners();

    await _streamSubscription?.cancel();
    _streamSubscription = null;

    final reqId = _currentRequestId;
    if (reqId != null) {
      await aiService.cancelRequest(reqId);
      final cancelMetrics = _requestMetricsMap[reqId]?.copyWith(
        completed: DateTime.now(),
        cancelled: true,
      );
      if (cancelMetrics != null) {
        _requestMetricsMap[reqId] = cancelMetrics;
      }
    }

    final partialText = activeStreamedMessage.value?.content ?? '';
    final partialReasoning = activeStreamedMessage.value?.reasoning ?? '';
    
    final cancelledMsg = ChatMessage(
      role: ChatRole.assistant,
      content: '$partialText [Generation Cancelled]',
      reasoning: partialReasoning.isNotEmpty ? partialReasoning : null,
      timestamp: DateTime.now(),
      metadata: MessageMetadata(
        providerId: _state.activeProviderId,
        modelId: _state.activeModelId,
        latencyMs: reqId != null ? _requestMetricsMap[reqId]?.latencyMs : null,
        ttftMs: reqId != null ? _requestMetricsMap[reqId]?.ttftMs : null,
        generatedAt: DateTime.now(),
      ),
    );

    final updatedMsgs = List<ChatMessage>.from(_state.messages)
      ..add(cancelledMsg);
    final updatedSession = _state.session!.copyWith(
      messages: updatedMsgs,
      updatedAt: DateTime.now(),
    );

    _updateHistorySession(updatedSession);
    _state = _state.copyWith(
      session: updatedSession,
      messages: updatedMsgs,
      streamState: ChatStreamState.cancelled,
      requestStage: RequestStage.cancelled,
    );
    activeStreamedMessage.value = null;
    _currentRequestId = null;
    notifyListeners();

    // Reset to idle on microtask boundary
    Future.microtask(() {
      _state = _state.copyWith(streamState: ChatStreamState.idle);
      notifyListeners();
    });
  }

  Future<void> retryLastPrompt() async {
    if (_state.messages.isEmpty) return;

    // Find last user message
    final lastUserIdx = _state.messages.lastIndexWhere(
      (m) => m.role == ChatRole.user,
    );
    if (lastUserIdx == -1) return;

    final promptText = _state.messages[lastUserIdx].content;

    // Remove any assistant responses after this user message
    final prunedMessages = _state.messages.sublist(0, lastUserIdx);
    final updatedSession = _state.session!.copyWith(
      messages: prunedMessages,
      updatedAt: DateTime.now(),
    );

    _updateHistorySession(updatedSession);
    _state = _state.copyWith(
      session: updatedSession,
      messages: prunedMessages,
      streamState: ChatStreamState.idle,
    );
    activeStreamedMessage.value = null;
    notifyListeners();

    await sendPrompt(promptText);
  }

  Future<void> submitPermissionDecision(String toolCallId, PermissionDecision decision) async {
    final updated = _state.toolCalls.map((t) {
      if (t.toolCallId == toolCallId) {
        if (decision == PermissionDecision.allowOnce || decision == PermissionDecision.allowAlways) {
          return t.copyWith(status: ToolCallStatus.running);
        } else {
          return t.copyWith(status: ToolCallStatus.failed, errorMessage: 'Permission Denied');
        }
      }
      return t;
    }).toList();

    _state = _state.copyWith(toolCalls: updated);
    notifyListeners();

    await aiService.sendPermissionResponse(
      toolCallId: toolCallId,
      decision: decision.name,
    );
  }

  void _updateHistorySession(ConversationSession updated) {
    final idx = _historyList.indexWhere((s) => s.id == updated.id);
    if (idx != -1) {
      _historyList[idx] = updated;
    }
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    activeStreamedMessage.dispose();
    super.dispose();
  }
}
