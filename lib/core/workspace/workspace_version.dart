class WorkspaceVersion {
  final int schemaVersion;
  final String engineVersion;
  final DateTime generatedAt;

  const WorkspaceVersion({
    required this.schemaVersion,
    required this.engineVersion,
    required this.generatedAt,
  });
}
