import 'conversation.dart';

class MemoryManager {
  final int maxMessages;

  MemoryManager({this.maxMessages = 20});

  List<Message> process(List<Message> history) {
    if (history.length <= maxMessages) {
      return history;
    }
    final processed = <Message>[];
    if (history.isNotEmpty && history.first.role == MessageRole.system) {
      processed.add(history.first);
    }
    final startIdx =
        history.length - maxMessages + (processed.isNotEmpty ? 1 : 0);
    processed.addAll(history.sublist(startIdx));
    return processed;
  }

  String summarize(List<Message> history) {
    return "Conversation Summary: Discussed code optimization and model adapters.";
  }
}
