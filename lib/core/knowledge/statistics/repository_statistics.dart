class RepositoryStatistics {
  final int documents;
  final int chunks;
  final int symbols;
  final int relations;
  final int embeddings;
  final int vectorCount;
  final Map<String, int> languages;
  final Duration indexDuration;
  final DateTime lastIndexed;
  final String workspaceHash;

  const RepositoryStatistics({
    required this.documents,
    required this.chunks,
    required this.symbols,
    required this.relations,
    required this.embeddings,
    required this.vectorCount,
    required this.languages,
    required this.indexDuration,
    required this.lastIndexed,
    required this.workspaceHash,
  });
}
