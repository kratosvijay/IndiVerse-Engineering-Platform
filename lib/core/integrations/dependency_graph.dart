class DependencyNode {
  final String id;
  final List<String> dependencies;

  DependencyNode(this.id, this.dependencies);
}

class DependencyGraph {
  final Map<String, DependencyNode> _nodes = {};

  void addNode(String id, List<String> deps) {
    _nodes[id] = DependencyNode(id, deps);
  }

  List<String> getResolveOrder() {
    final visited = <String>{};
    final temp = <String>{};
    final order = <String>[];

    void visit(String node) {
      if (visited.contains(node)) return;
      if (temp.contains(node)) {
        throw StateError("Circular dependency detected for: $node");
      }
      temp.add(node);
      final deps = _nodes[node]?.dependencies ?? [];
      for (final dep in deps) {
        if (_nodes.containsKey(dep)) {
          visit(dep);
        }
      }
      temp.remove(node);
      visited.add(node);
      order.add(node);
    }

    for (final node in _nodes.keys) {
      visit(node);
    }
    return order;
  }
}
