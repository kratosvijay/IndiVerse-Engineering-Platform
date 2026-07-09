import 'dart:math';
import 'embedding_provider.dart';

class VectorItem {
  final String id;
  final Embedding embedding;
  final Map<String, dynamic> payload;

  const VectorItem({
    required this.id,
    required this.embedding,
    required this.payload,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'embedding': embedding.toJson(),
        'payload': payload,
      };

  factory VectorItem.fromJson(Map<String, dynamic> json) => VectorItem(
        id: json['id'] as String,
        embedding:
            Embedding.fromJson(json['embedding'] as Map<String, dynamic>),
        payload: json['payload'] as Map<String, dynamic>,
      );
}

class VectorSearchResult {
  final VectorItem item;
  final double score;

  const VectorSearchResult({
    required this.item,
    required this.score,
  });
}

abstract class VectorStore {
  Future<void> insert(VectorItem item);
  Future<void> delete(String id);
  Future<void> update(VectorItem item);
  Future<List<VectorSearchResult>> search(Embedding query,
      {int limit = 5, double minScore = 0.0});
  Future<void> clear();
}

class MemoryVectorStore implements VectorStore {
  final Map<String, VectorItem> _items = {};

  @override
  Future<void> insert(VectorItem item) async {
    _items[item.id] = item;
  }

  @override
  Future<void> delete(String id) async {
    _items.remove(id);
  }

  @override
  Future<void> update(VectorItem item) async {
    _items[item.id] = item;
  }

  @override
  Future<void> clear() async {
    _items.clear();
  }

  @override
  Future<List<VectorSearchResult>> search(Embedding query,
      {int limit = 5, double minScore = 0.0}) async {
    final results = <VectorSearchResult>[];

    for (final item in _items.values) {
      final similarity = cosineSimilarity(query.vector, item.embedding.vector);
      if (similarity >= minScore) {
        results.add(VectorSearchResult(item: item, score: similarity));
      }
    }

    // Sort descending by score
    results.sort((a, b) => b.score.compareTo(a.score));

    if (results.length > limit) {
      return results.sublist(0, limit);
    }
    return results;
  }

  // Calculates cosine similarity between two double vectors
  double cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) return 0.0;
    var dotProduct = 0.0;
    var normA = 0.0;
    var normB = 0.0;

    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    if (normA == 0.0 || normB == 0.0) return 0.0;
    return dotProduct / (sqrt(normA) * sqrt(normB));
  }
}
