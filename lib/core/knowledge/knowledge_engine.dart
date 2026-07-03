import 'contracts/embedding_provider.dart';
import 'contracts/vector_store.dart';
import 'knowledge_graph.dart';
import 'contracts/search_engine.dart';

class KnowledgeEngine {
  final EmbeddingProvider embeddingProvider;
  final VectorStore vectorStore;
  final KnowledgeGraph graph;
  final SearchEngine searchEngine;

  KnowledgeEngine({
    required this.embeddingProvider,
    required this.vectorStore,
    required this.graph,
    required this.searchEngine,
  });
}
