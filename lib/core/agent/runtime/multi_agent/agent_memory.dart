import '../../../workspace/index/build_intelligence.dart';

class ArtifactStore {
  final Map<String, String> _artifacts = {};

  void publish(String id, String content) {
    _artifacts[id] = content;
  }

  String? get(String id) => _artifacts[id];
  Map<String, String> get all => Map.unmodifiable(_artifacts);
}

class DiagnosticStore {
  final List<BuildDiagnostic> _diagnostics = [];

  void add(BuildDiagnostic d) {
    _diagnostics.add(d);
  }

  List<BuildDiagnostic> get all => List.unmodifiable(_diagnostics);
}

class ReasoningStore {
  final Map<String, List<String>> _reasoningLogs = {};

  void record(String agentId, String log) {
    _reasoningLogs.putIfAbsent(agentId, () => []).add(log);
  }

  List<String> getForAgent(String agentId) =>
      List.unmodifiable(_reasoningLogs[agentId] ?? []);
  Map<String, List<String>> get all => Map.unmodifiable(_reasoningLogs);
}

class WorkspaceFactStore {
  final List<String> _facts = [];

  void addFact(String fact) {
    _facts.add(fact);
  }

  List<String> get all => List.unmodifiable(_facts);
}

class SharedMemory {
  final ArtifactStore artifacts = ArtifactStore();
  final DiagnosticStore diagnostics = DiagnosticStore();
  final ReasoningStore reasoning = ReasoningStore();
  final WorkspaceFactStore facts = WorkspaceFactStore();

  void clear() {
    artifacts._artifacts.clear();
    diagnostics._diagnostics.clear();
    reasoning._reasoningLogs.clear();
    facts._facts.clear();
  }
}
