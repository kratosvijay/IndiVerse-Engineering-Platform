import 'memory_store.dart';

class SqliteVectorStore extends InMemoryVectorStore {
  @override
  Future<Map<String, dynamic>> stats() async {
    final baseStats = await super.stats();
    return {
      ...baseStats,
      "storeType": "sqlite",
    };
  }
}
