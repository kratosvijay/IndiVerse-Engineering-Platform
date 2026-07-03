class IndexManifest {
  final int schemaVersion;
  final String workspaceVersion;
  final String embeddingProvider;
  final String embeddingModel;
  final int embeddingDimension;
  final String graphVersion;
  final String chunkerVersion;
  final Map<String, String> extractorVersions;
  final DateTime createdAt;
  final DateTime updatedAt;

  const IndexManifest({
    required this.schemaVersion,
    required this.workspaceVersion,
    required this.embeddingProvider,
    required this.embeddingModel,
    required this.embeddingDimension,
    required this.graphVersion,
    required this.chunkerVersion,
    required this.extractorVersions,
    required this.createdAt,
    required this.updatedAt,
  });
}
