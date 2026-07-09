enum DependencyType {
  importRelation,
  exportRelation,
  partRelation,
  partOfRelation
}

class ImportNode {
  final String filePath;

  const ImportNode(this.filePath);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImportNode &&
          runtimeType == other.runtimeType &&
          filePath == other.filePath;

  @override
  int get hashCode => filePath.hashCode;
}

class ImportEdge {
  final String fromPath;
  final String toPath;
  final DependencyType type;

  const ImportEdge({
    required this.fromPath,
    required this.toPath,
    required this.type,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImportEdge &&
          runtimeType == other.runtimeType &&
          fromPath == other.fromPath &&
          toPath == other.toPath &&
          type == other.type;

  @override
  int get hashCode => fromPath.hashCode ^ toPath.hashCode ^ type.hashCode;
}

class DependencyGraph {
  final Map<String, List<ImportEdge>> _adjacencyList = {};

  void addDependency(String from, String to, DependencyType type) {
    final edge = ImportEdge(fromPath: from, toPath: to, type: type);
    final edges = _adjacencyList.putIfAbsent(from, () => []);
    if (!edges.contains(edge)) {
      edges.add(edge);
    }
  }

  void addEdge(String from, String to) {
    addDependency(from, to, DependencyType.importRelation);
  }

  void removeDependenciesForFile(String filePath) {
    _adjacencyList.remove(filePath);
    // Also remove from any values where it's a target
    for (final edges in _adjacencyList.values) {
      edges.removeWhere((edge) => edge.toPath == filePath);
    }
  }

  void clear() {
    _adjacencyList.clear();
  }

  List<ImportEdge> getEdges(String filePath) {
    return List.unmodifiable(_adjacencyList[filePath] ?? []);
  }

  List<String> getDependencies(String filePath) {
    return dependenciesOf(filePath);
  }

  List<String> dependenciesOf(String filePath) {
    return (_adjacencyList[filePath] ?? []).map((edge) => edge.toPath).toList();
  }

  List<String> dependentsOf(String filePath) {
    final dependents = <String>[];
    _adjacencyList.forEach((source, edges) {
      if (edges.any((edge) => edge.toPath == filePath)) {
        dependents.add(source);
      }
    });
    return dependents;
  }

  bool hasCycles() {
    final visited = <String, int>{}; // 0 = unvisited, 1 = visiting, 2 = visited

    bool dfs(String node) {
      visited[node] = 1;
      final edges = _adjacencyList[node] ?? [];
      for (final edge in edges) {
        final neighbor = edge.toPath;
        final state = visited[neighbor] ?? 0;
        if (state == 1) return true;
        if (state == 0) {
          if (dfs(neighbor)) return true;
        }
      }
      visited[node] = 2;
      return false;
    }

    for (final node in _adjacencyList.keys) {
      if ((visited[node] ?? 0) == 0) {
        if (dfs(node)) return true;
      }
    }
    return false;
  }

  List<String>? shortestPath(String start, String end) {
    if (start == end) return [start];

    final queue = <List<String>>[
      [start]
    ];
    final visited = <String>{start};

    while (queue.isNotEmpty) {
      final path = queue.removeAt(0);
      final current = path.last;

      if (current == end) return path;

      final edges = _adjacencyList[current] ?? [];
      for (final edge in edges) {
        final neighbor = edge.toPath;
        if (!visited.contains(neighbor)) {
          visited.add(neighbor);
          queue.add([...path, neighbor]);
        }
      }
    }
    return null;
  }
}
