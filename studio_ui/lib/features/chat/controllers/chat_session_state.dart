import '../../../models/ai_models.dart';
import 'package:indiverse_developer_platform/core/models/tool_call_models.dart';

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
  final RequestStage? requestStage;
  final String? activeProviderId;
  final String? activeModelId;
  final String? error;
  final List<ToolCallState> toolCalls;

  const ChatSessionState({
    this.session,
    this.messages = const [],
    this.streamState = ChatStreamState.idle,
    this.requestStage,
    this.activeProviderId,
    this.activeModelId,
    this.error,
    this.toolCalls = const [],
  });

  ChatSessionState copyWith({
    ConversationSession? session,
    List<ChatMessage>? messages,
    ChatStreamState? streamState,
    RequestStage? requestStage,
    String? activeProviderId,
    String? activeModelId,
    String? error,
    bool clearError = false,
    List<ToolCallState>? toolCalls,
  }) {
    return ChatSessionState(
      session: session ?? this.session,
      messages: messages ?? this.messages,
      streamState: streamState ?? this.streamState,
      requestStage: requestStage ?? this.requestStage,
      activeProviderId: activeProviderId ?? this.activeProviderId,
      activeModelId: activeModelId ?? this.activeModelId,
      error: clearError ? null : (error ?? this.error),
      toolCalls: toolCalls ?? this.toolCalls,
    );
  }
}
