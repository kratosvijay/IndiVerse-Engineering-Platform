import 'package:test/test.dart';
import 'package:indiverse_developer_platform/core/conversation/conversation.dart';
import 'package:indiverse_developer_platform/core/conversation/memory_manager.dart';

void main() {
  group('Conversation & Memory Tests', () {
    test('should prune history to fit context limits', () {
      final memory = MemoryManager(maxMessages: 3);
      final history = [
        Message(role: MessageRole.system, content: "System setup"),
        Message(role: MessageRole.user, content: "Hello 1"),
        Message(role: MessageRole.model, content: "Hi 1"),
        Message(role: MessageRole.user, content: "Hello 2"),
        Message(role: MessageRole.model, content: "Hi 2"),
      ];

      final processed = memory.process(history);
      expect(processed.length, 3);
      expect(processed.first.role,
          MessageRole.system); // retained system instructions
      expect(processed[1].content, "Hello 2");
      expect(processed[2].content, "Hi 2");
    });
  });
}
