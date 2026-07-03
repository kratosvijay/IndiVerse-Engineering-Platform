import 'dart:convert';
import 'dart:io';
import 'package:indiverse_developer_platform/core/knowledge/knowledge_engine.dart';
import 'package:indiverse_developer_platform/core/knowledge/providers/gemini_embedding.dart';
import 'package:indiverse_developer_platform/core/knowledge/stores/memory_store.dart';
import 'package:indiverse_developer_platform/core/knowledge/knowledge_graph.dart';
import 'package:indiverse_developer_platform/core/knowledge/search_engine.dart';
import 'package:indiverse_developer_platform/core/knowledge/search/semantic_search.dart';

void main() async {
  final provider = GeminiEmbeddingProvider();
  final store = InMemoryVectorStore();
  final graph = KnowledgeGraph();
  final searchEngine =
      SearchEngineImpl(embeddingProvider: provider, vectorStore: store);

  final stopwatch = Stopwatch()..start();
  final _ = KnowledgeEngine(
    embeddingProvider: provider,
    vectorStore: store,
    graph: graph,
    searchEngine: searchEngine,
  );
  await searchEngine.query(const SearchQuery(text: "example search query"));
  stopwatch.stop();
  final ms = stopwatch.elapsedMilliseconds;
  final report = {
    "metric": "semanticSearchTimeMs",
    "value": ms,
    "threshold": 500,
    "status": ms < 500 ? "PASS" : "FAIL"
  };
  File('benchmark/reports/knowledge.json')
      .writeAsStringSync(jsonEncode(report));
  print("Semantic search time: $ms ms");
}
