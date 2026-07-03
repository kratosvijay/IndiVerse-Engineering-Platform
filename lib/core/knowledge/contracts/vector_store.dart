abstract class VectorStore {
  Future<void> insert(
      String id, List<double> vector, Map<String, dynamic> metadata);
  Future<void> update(
      String id, List<double> vector, Map<String, dynamic> metadata);
  Future<void> delete(String id);
  Future<List<SearchResultItem>> search(List<double> queryVector,
      {required int limit});
  Future<List<SearchResultItem>> searchHybrid(
      List<double> queryVector, String textQuery,
      {required int limit});
  Future<List<SearchResultItem>> searchByMetadata(Map<String, dynamic> filters,
      {required int limit});
  Future<void> clear();
  Future<Map<String, dynamic>> stats();
  Future<void> compact();
}

class SearchResultItem {
  final String id;
  final double score;
  final Map<String, dynamic> metadata;

  const SearchResultItem(this.id, this.score, this.metadata);
}
