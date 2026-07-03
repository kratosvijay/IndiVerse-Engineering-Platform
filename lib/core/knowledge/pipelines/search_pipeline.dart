import '../contracts/search_engine.dart';
import '../search/semantic_search.dart';

class SearchPipeline {
  final SearchEngine engine;

  SearchPipeline({required this.engine});

  Future<List<SearchResult>> execute(SearchQuery query) async {
    return await engine.query(query);
  }
}
