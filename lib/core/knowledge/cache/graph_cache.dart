class GraphCache {
  final Map<String, List<String>> _cache = {};

  void save(String node, List<String> edges) {
    _cache[node] = edges;
  }

  List<String>? get(String node) => _cache[node];

  void clear() => _cache.clear();
}
