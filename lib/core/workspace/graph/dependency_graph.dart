class DependencyGraph {
  final Map<String, List<String>> _graph = {};

  void addEdge(String from, String to) {
    _graph.putIfAbsent(from, () => []).add(to);
  }

  Map<String, List<String>> get graph => Map.unmodifiable(_graph);

  List<String> getDependencies(String project) => _graph[project] ?? [];
}
