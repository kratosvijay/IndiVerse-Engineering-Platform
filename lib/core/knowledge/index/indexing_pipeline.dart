import '../contracts/embedding_provider.dart';
import '../contracts/vector_store.dart';
import '../contracts/symbol_extractor.dart';
import '../contracts/chunker.dart';
import '../document.dart';

import '../knowledge_graph.dart';
import '../graph/relation.dart';
import '../graph/relation_type.dart';
import '../cache/embedding_cache.dart';
import '../index/index_progress.dart';

class IndexingPipeline {
  final EmbeddingProvider embeddingProvider;
  final VectorStore vectorStore;
  final List<SymbolExtractor> extractors;
  final Chunker chunker;
  final KnowledgeGraph graph;
  final EmbeddingCache cache;

  IndexingPipeline({
    required this.embeddingProvider,
    required this.vectorStore,
    required this.extractors,
    required this.chunker,
    required this.graph,
    required this.cache,
  });

  Future<void> indexDocument(Document doc,
      {void Function(IndexProgress)? onProgress}) async {
    final chunks = chunker.chunk(doc);
    for (int i = 0; i < chunks.length; i++) {
      final chunk = chunks[i];
      List<double>? vector = cache.get(chunk.checksum);
      if (vector == null) {
        vector = await embeddingProvider.getEmbedding(chunk.content);
        cache.save(chunk.checksum, vector);
      }
      await vectorStore.insert(chunk.id, vector, {
        "documentId": doc.id,
        "startLine": chunk.startLine,
        "endLine": chunk.endLine,
        "language": chunk.language,
      });
      onProgress?.call(IndexProgress(chunks.length, i + 1));
    }

    for (final extractor in extractors) {
      if (extractor.language == doc.language) {
        final symbols = await extractor.extract(doc.content, doc.uri);
        for (final sym in symbols) {
          graph.addRelation(Relation(
            from: doc.uri,
            to: sym.id,
            type: RelationType.contains,
          ));
        }
      }
    }
  }
}
