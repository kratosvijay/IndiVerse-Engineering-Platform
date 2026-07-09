import 'vector_store.dart';
import 'knowledge_manager.dart';

class RetrieverPipeline {
  final KnowledgeManager manager;

  const RetrieverPipeline({
    required this.manager,
  });

  // Queries the vector store, resolves canonical document titles/metadata, and builds formatted context
  Future<List<VectorSearchResult>> retrieve(String queryText,
      {int limit = 5, double minScore = 0.0}) async {
    final queryEmbedding = await manager.embeddingProvider.embedText(queryText);
    return manager.vectorStore
        .search(queryEmbedding, limit: limit, minScore: minScore);
  }

  Future<String> retrieveAndBuildContext(String queryText,
      {int limit = 3, double minScore = 0.1}) async {
    final results = await retrieve(queryText, limit: limit, minScore: minScore);
    if (results.isEmpty) {
      return '';
    }

    final buffer = StringBuffer();
    buffer.writeln('### Relevant Persistent Knowledge & Long-Term Memories');

    for (final res in results) {
      final docId = res.item.payload['documentId'] as String;
      final text = res.item.payload['text'] as String;
      final category = res.item.payload['category'] as String;

      final doc = manager.store.get(docId);
      final title = doc?.title ?? 'Untitled Document';
      final scorePct = (res.score * 100).toStringAsFixed(1);

      buffer.writeln(
          '- **$title** (Category: $category, Relevance: $scorePct%):');
      buffer.writeln('  > $text');
      buffer.writeln();
    }

    return buffer.toString().trim();
  }
}
