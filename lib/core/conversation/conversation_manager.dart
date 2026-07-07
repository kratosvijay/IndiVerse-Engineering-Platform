import 'dart:async';
import '../providers/ai_provider.dart';

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

abstract class ConversationStore {
  Future<void> saveSession(ConversationSession session);
  Future<ConversationSession?> getSession(String id);
  Future<List<ConversationSession>> listSessions(String workspace);
  Future<void> deleteSession(String id);
}

class MemoryConversationStore implements ConversationStore {
  final Map<String, ConversationSession> _sessions = {};

  @override
  Future<void> saveSession(ConversationSession session) async {
    _sessions[session.id] = session;
  }

  @override
  Future<ConversationSession?> getSession(String id) async {
    return _sessions[id];
  }

  @override
  Future<List<ConversationSession>> listSessions(String workspace) async {
    return _sessions.values.where((s) => s.workspace == workspace).toList();
  }

  @override
  Future<void> deleteSession(String id) async {
    _sessions.remove(id);
  }
}

class ConversationManager {
  final ConversationStore store;

  ConversationManager(this.store);

  Future<ConversationSession> createSession({
    required String id,
    required String title,
    required String workspace,
    required String providerId,
    required String modelId,
  }) async {
    final now = DateTime.now();
    final session = ConversationSession(
      id: id,
      title: title,
      workspace: workspace,
      providerId: providerId,
      modelId: modelId,
      messages: const [],
      estimatedTokens: 0,
      createdAt: now,
      updatedAt: now,
    );
    await store.saveSession(session);
    return session;
  }

  Future<ConversationSession?> getSession(String id) {
    return store.getSession(id);
  }

  Future<ConversationSession> appendMessage(
    String id,
    ChatMessage message,
  ) async {
    final session = await store.getSession(id);
    if (session == null) {
      throw Exception("Session not found: $id");
    }

    final newMessages = List<ChatMessage>.from(session.messages)..add(message);
    final updatedSession = session.copyWith(
      messages: newMessages,
      estimatedTokens: _estimateTokens(newMessages),
      updatedAt: DateTime.now(),
    );

    await store.saveSession(updatedSession);
    return updatedSession;
  }

  int _estimateTokens(List<ChatMessage> messages) {
    int count = 0;
    for (final msg in messages) {
      // Crude approximation: ~4 characters per token
      count += (msg.content.length / 4.0).ceil();
    }
    return count;
  }
}
