import '../../../models/ai_models.dart';

enum ChatStreamState {
  idle,
  preparing,
  waitingFirstToken,
  streaming,
  finishing,
  stopping,
  completed,
  cancelled,
  failed,
}

class ChatSessionState {
  final ConversationSession? session;
  final List<ChatMessage> messages;
  final ChatStreamState streamState;
  final String? activeProviderId;
  final String? activeModelId;
  final String? error;

  const ChatSessionState({
    this.session,
    this.messages = const [],
    this.streamState = ChatStreamState.idle,
    this.activeProviderId,
    this.activeModelId,
    this.error,
  });

  ChatSessionState copyWith({
    ConversationSession? session,
    List<ChatMessage>? messages,
    ChatStreamState? streamState,
    String? activeProviderId,
    String? activeModelId,
    String? error,
    bool clearError = false,
  }) {
    return ChatSessionState(
      session: session ?? this.session,
      messages: messages ?? this.messages,
      streamState: streamState ?? this.streamState,
      activeProviderId: activeProviderId ?? this.activeProviderId,
      activeModelId: activeModelId ?? this.activeModelId,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
