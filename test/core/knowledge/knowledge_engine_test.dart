import 'package:test/test.dart';
import 'package:indiverse_developer_platform/core/knowledge/knowledge_engine.dart';
import 'package:indiverse_developer_platform/core/knowledge/providers/gemini_embedding.dart';
import 'package:indiverse_developer_platform/core/knowledge/stores/memory_store.dart';
import 'package:indiverse_developer_platform/core/knowledge/knowledge_graph.dart';
import 'package:indiverse_developer_platform/core/knowledge/search_engine.dart';
import 'package:indiverse_developer_platform/core/knowledge/index/indexing_pipeline.dart';
import 'package:indiverse_developer_platform/core/knowledge/chunkers/line_chunker.dart';
import 'package:indiverse_developer_platform/core/knowledge/extractors/dart_extractor.dart';
import 'package:indiverse_developer_platform/core/knowledge/cache/embedding_cache.dart';
import 'package:indiverse_developer_platform/core/knowledge/document.dart';
import 'package:indiverse_developer_platform/core/knowledge/search/semantic_search.dart';

void main() {
  group('KnowledgeEngine Tests', () {
    test('Orchestrated index and retrieval pipeline', () async {
      final provider = GeminiEmbeddingProvider();
      final store = InMemoryVectorStore();
      final graph = KnowledgeGraph();
      final searchEngine =
          SearchEngineImpl(embeddingProvider: provider, vectorStore: store);
      final cache = EmbeddingCache();

      final engine = KnowledgeEngine(
        embeddingProvider: provider,
        vectorStore: store,
        graph: graph,
        searchEngine: searchEngine,
      );
      expect(engine, isNotNull);

      final indexPipeline = IndexingPipeline(
        embeddingProvider: provider,
        vectorStore: store,
        extractors: [DartExtractor()],
        chunker: const LineChunker(),
        graph: graph,
        cache: cache,
      );

      const doc = Document(
        id: 'lib/service.dart',
        uri: 'lib/service.dart',
        content: 'class Service {}',
        language: 'dart',
        checksum: '111',
        metadata: {},
      );

      await indexPipeline.indexDocument(doc);

      final results =
          await searchEngine.query(const SearchQuery(text: 'query widget'));
      expect(results.isNotEmpty, isTrue);
      expect(graph.relations.length, equals(1));
    });
  });
}
