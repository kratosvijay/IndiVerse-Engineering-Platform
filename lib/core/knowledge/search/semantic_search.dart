import '../document.dart';
import '../chunk.dart';

class SearchQuery {
  final String text;
  final Map<String, dynamic> filters;
  final String workspace;
  final String language;
  final List<String> fileTypes;
  final List<String> tags;
  final int limit;
  final int budget;

  const SearchQuery({
    required this.text,
    this.filters = const {},
    this.workspace = "",
    this.language = "",
    this.fileTypes = const [],
    this.tags = const [],
    this.limit = 5,
    this.budget = 4000,
  });
}

class SearchResult {
  final Document document;
  final Chunk chunk;
  final double score;
  final List<String> matchedSymbols;
  final List<String> matchedRelations;
  final List<String> rankingReasons;
  final List<String> contextSources;
  final String provider;

  const SearchResult({
    required this.document,
    required this.chunk,
    required this.score,
    required this.matchedSymbols,
    required this.matchedRelations,
    required this.rankingReasons,
    required this.contextSources,
    required this.provider,
  });
}
