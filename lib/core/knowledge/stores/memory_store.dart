import 'dart:math';
import '../contracts/vector_store.dart';

class InMemoryVectorStore implements VectorStore {
  final Map<String, List<double>> _vectors = {};
  final Map<String, Map<String, dynamic>> _metadata = {};

  @override
  Future<void> insert(
      String id, List<double> vector, Map<String, dynamic> metadata) async {
    _vectors[id] = vector;
    _metadata[id] = metadata;
  }

  @override
  Future<void> update(
      String id, List<double> vector, Map<String, dynamic> metadata) async {
    _vectors[id] = vector;
    _metadata[id] = metadata;
  }

  @override
  Future<void> delete(String id) async {
    _vectors.remove(id);
    _metadata.remove(id);
  }

  double _dotProduct(List<double> a, List<double> b) {
    double dot = 0.0;
    for (int i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
    }
    return dot;
  }

  double _magnitude(List<double> a) {
    double sum = 0.0;
    for (int i = 0; i < a.length; i++) {
      sum += a[i] * a[i];
    }
    return sqrt(sum);
  }

  double _cosineSimilarity(List<double> a, List<double> b) {
    final magA = _magnitude(a);
    final magB = _magnitude(b);
    if (magA == 0.0 || magB == 0.0) return 0.0;
    return _dotProduct(a, b) / (magA * magB);
  }

  @override
  Future<List<SearchResultItem>> search(List<double> queryVector,
      {required int limit}) async {
    final results = <SearchResultItem>[];
    _vectors.forEach((id, vector) {
      final similarity = _cosineSimilarity(queryVector, vector);
      results.add(SearchResultItem(id, similarity, _metadata[id] ?? {}));
    });
    results.sort((a, b) => b.score.compareTo(a.score));
    return results.take(limit).toList();
  }

  @override
  Future<List<SearchResultItem>> searchHybrid(
      List<double> queryVector, String textQuery,
      {required int limit}) async {
    return await search(queryVector, limit: limit);
  }

  @override
  Future<List<SearchResultItem>> searchByMetadata(Map<String, dynamic> filters,
      {required int limit}) async {
    final results = <SearchResultItem>[];
    _metadata.forEach((id, meta) {
      bool matches = true;
      filters.forEach((key, val) {
        if (meta[key] != val) matches = false;
      });
      if (matches) {
        results.add(SearchResultItem(id, 1.0, meta));
      }
    });
    return results.take(limit).toList();
  }

  @override
  Future<void> clear() async {
    _vectors.clear();
    _metadata.clear();
  }

  @override
  Future<Map<String, dynamic>> stats() async {
    return {
      "count": _vectors.length,
      "dimensions": _vectors.values.isEmpty ? 0 : _vectors.values.first.length,
    };
  }

  @override
  Future<void> compact() async {}
}
