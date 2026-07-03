enum MessageRole { user, model, system }

class Message {
  final MessageRole role;
  final String content;
  final DateTime timestamp;

  Message({
    required this.role,
    required this.content,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'role': role.name,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
      };

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        role: MessageRole.values.firstWhere((e) => e.name == json['role']),
        content: json['content'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

class Conversation {
  final String id;
  final List<Message> _messages = [];

  Conversation(this.id);

  List<Message> get messages => List.unmodifiable(_messages);

  void addMessage(Message message) {
    _messages.add(message);
  }

  void clear() {
    _messages.clear();
  }
}
