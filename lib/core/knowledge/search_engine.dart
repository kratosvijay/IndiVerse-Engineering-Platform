import 'contracts/search_engine.dart';
import 'search/semantic_search.dart';
import 'contracts/vector_store.dart';
import 'contracts/embedding_provider.dart';
import 'document.dart';
import 'chunk.dart';

class SearchEngineImpl implements SearchEngine {
  final EmbeddingProvider embeddingProvider;
  final VectorStore vectorStore;

  SearchEngineImpl(
      {required this.embeddingProvider, required this.vectorStore});

  @override
  Future<List<SearchResult>> query(SearchQuery query) async {
    final queryVector = await embeddingProvider.getEmbedding(query.text);
    final results = await vectorStore.search(queryVector, limit: query.limit);

    final searchResults = <SearchResult>[];
    for (final item in results) {
      final docId = item.metadata["documentId"] as String? ?? "";
      final startLine = item.metadata["startLine"] as int? ?? 1;
      final endLine = item.metadata["endLine"] as int? ?? 1;
      final language = item.metadata["language"] as String? ?? "";

      final mockDoc = Document(
        id: docId,
        uri: docId,
        content: "",
        language: language,
        checksum: "",
        metadata: const {},
      );

      final mockChunk = Chunk(
        id: item.id,
        documentId: docId,
        startLine: startLine,
        endLine: endLine,
        content: "",
        checksum: "",
        language: language,
        symbolIds: const [],
        tokenCount: 0,
        metadata: item.metadata,
      );

      searchResults.add(SearchResult(
        document: mockDoc,
        chunk: mockChunk,
        score: item.score,
        matchedSymbols: const [],
        matchedRelations: const [],
        rankingReasons: const ["Cosine similarity match"],
        contextSources: [docId],
        provider: embeddingProvider.name,
      ));
    }
    return searchResults;
  }
}
