import 'workspace_indexer.dart';
import '../workspace_cache.dart';

class IncrementalIndexer {
  final WorkspaceCache cache;
  final WorkspaceIndexer indexer;

  IncrementalIndexer({required this.cache, required this.indexer});

  Future<IndexStatistics> indexChanges(
      String rootPath, List<String> changedFiles) async {
    for (final filepath in changedFiles) {
      cache.updateFileHash(filepath, "mock-hash-value");
    }
    return indexer.index(rootPath);
  }
}
