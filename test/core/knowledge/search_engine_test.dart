import 'package:test/test.dart';
import 'package:indiverse_developer_platform/core/knowledge/search_engine.dart';
import 'package:indiverse_developer_platform/core/knowledge/providers/gemini_embedding.dart';
import 'package:indiverse_developer_platform/core/knowledge/stores/memory_store.dart';
import 'package:indiverse_developer_platform/core/knowledge/search/semantic_search.dart';

void main() {
  group('SearchEngine Tests', () {
    test('Semantic query yields matches with explainability', () async {
      final provider = GeminiEmbeddingProvider();
      final store = InMemoryVectorStore();
      final searchEngine =
          SearchEngineImpl(embeddingProvider: provider, vectorStore: store);

      await store.insert('chunk-1', List.generate(768, (i) => 0.1), {
        'documentId': 'file.dart',
        'startLine': 1,
        'endLine': 10,
        'language': 'dart',
      });

      final results =
          await searchEngine.query(const SearchQuery(text: 'find mock widget'));
      expect(results.length, equals(1));
      expect(results[0].document.id, equals('file.dart'));
      expect(results[0].chunk.id, equals('chunk-1'));
      expect(results[0].rankingReasons[0], equals('Cosine similarity match'));
    });
  });
}
