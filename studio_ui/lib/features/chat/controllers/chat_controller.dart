import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/services/ai_service.dart';
import '../../../models/ai_models.dart';
import 'chat_session_state.dart';

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

  ChatController({required this.aiService, required this.workspace});

  Future<void> initialize() async {
    await fetchProvidersAndModels();
    await createNewSession("New Conversation");
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
      title: currentSession.messages.isEmpty ? trimmed : currentSession.title,
      updatedAt: DateTime.now(),
    );

    _updateHistorySession(currentSession);
    _state = _state.copyWith(
      session: currentSession,
      messages: updatedMessages,
      streamState: ChatStreamState.preparing,
      clearError: true,
    );
    activeStreamedMessage.value = null;
    notifyListeners();

    // 2. Start Stream
    final reqId = 'req-${DateTime.now().millisecondsSinceEpoch}';
    _currentRequestId = reqId;

    _state = _state.copyWith(streamState: ChatStreamState.waitingFirstToken);
    notifyListeners();

    final stream = aiService.chatStream(
      session: currentSession,
      requestId: reqId,
    );

    String accumulatedText = '';
    activeStreamedMessage.value = ChatMessage(
      role: ChatRole.assistant,
      content: '',
      timestamp: DateTime.now(),
    );

    _streamSubscription = stream.listen(
      (event) {
        if (_state.streamState == ChatStreamState.waitingFirstToken) {
          _state = _state.copyWith(streamState: ChatStreamState.streaming);
          notifyListeners();
        }

        if (event is TokenChunkEvent) {
          accumulatedText += event.chunk;
          activeStreamedMessage.value = ChatMessage(
            role: ChatRole.assistant,
            content: accumulatedText,
            timestamp: DateTime.now(),
          );
        } else if (event is ReasoningChunkEvent) {
          // Display reasoning Trace or prepend it in a collapsed format
          accumulatedText += '${event.reasoning}\n';
          activeStreamedMessage.value = ChatMessage(
            role: ChatRole.assistant,
            content: accumulatedText,
            timestamp: DateTime.now(),
          );
        } else if (event is ErrorEvent) {
          _state = _state.copyWith(
            streamState: ChatStreamState.failed,
            error: '${event.code}: ${event.message}',
          );
          notifyListeners();
        }
      },
      onError: (err) {
        _state = _state.copyWith(
          streamState: ChatStreamState.failed,
          error: err.toString(),
        );
        notifyListeners();
      },
      onDone: () {
        if (_state.streamState == ChatStreamState.streaming ||
            _state.streamState == ChatStreamState.waitingFirstToken) {
          _state = _state.copyWith(streamState: ChatStreamState.finishing);
          notifyListeners();

          final finalMsg = ChatMessage(
            role: ChatRole.assistant,
            content: accumulatedText.trim(),
            timestamp: DateTime.now(),
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
        _state = _state.copyWith(streamState: ChatStreamState.idle);
        notifyListeners();
        _currentRequestId = null;
      },
    );
  }

  Future<void> stopGeneration() async {
    if (_state.streamState == ChatStreamState.idle) return;

    _state = _state.copyWith(streamState: ChatStreamState.stopping);
    notifyListeners();

    await _streamSubscription?.cancel();
    _streamSubscription = null;

    if (_currentRequestId != null) {
      await aiService.cancelRequest(_currentRequestId!);
    }

    final partialText = activeStreamedMessage.value?.content ?? '';
    final cancelledMsg = ChatMessage(
      role: ChatRole.assistant,
      content: '$partialText [Generation Cancelled]',
      timestamp: DateTime.now(),
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
    );
    activeStreamedMessage.value = null;
    _currentRequestId = null;

    // Reset to idle
    _state = _state.copyWith(streamState: ChatStreamState.idle);
    notifyListeners();
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
