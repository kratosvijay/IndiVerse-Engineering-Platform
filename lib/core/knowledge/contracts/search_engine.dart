import '../search/semantic_search.dart';

abstract class SearchEngine {
  Future<List<SearchResult>> query(SearchQuery query);
}
