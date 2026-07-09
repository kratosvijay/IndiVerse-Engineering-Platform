import 'knowledge_item.dart';

enum MemorySegment {
  project,
  workspace,
  conversation,
  execution,
  agent,
  user,
  temporary
}

class MemoryManager {
  final Map<MemorySegment, List<KnowledgeDocument>> _segments = {};

  MemoryManager() {
    for (final segment in MemorySegment.values) {
      _segments[segment] = [];
    }
  }

  void save(MemorySegment segment, KnowledgeDocument doc) {
    _segments[segment]!.add(doc);
  }

  List<KnowledgeDocument> get(MemorySegment segment) {
    return List.unmodifiable(_segments[segment] ?? []);
  }

  void clear(MemorySegment segment) {
    _segments[segment]?.clear();
  }

  void clearAll() {
    for (final list in _segments.values) {
      list.clear();
    }
  }
}
