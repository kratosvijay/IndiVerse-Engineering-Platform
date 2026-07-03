import 'workspace_metadata.dart';

class Workspace {
  final String id;
  final String name;
  final String rootPath;
  final List<String> projectTypes;
  final List<String> repositories;
  final Map<String, dynamic> configuration;
  final WorkspaceMetadata metadata;

  const Workspace({
    required this.id,
    required this.name,
    required this.rootPath,
    required this.projectTypes,
    required this.repositories,
    required this.configuration,
    required this.metadata,
  });
}
