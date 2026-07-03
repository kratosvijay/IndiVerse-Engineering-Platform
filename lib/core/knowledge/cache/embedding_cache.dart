class EmbeddingCache {
  final Map<String, List<double>> _cache = {};

  void save(String checksum, List<double> vector) {
    _cache[checksum] = vector;
  }

  List<double>? get(String checksum) {
    return _cache[checksum];
  }

  void clear() => _cache.clear();
}
