import 'workspace_metadata.dart';
import '../providers/provider_health.dart';

class WorkspaceSnapshot {
  final WorkspaceMetadata metadata;
  final String currentBranch;
  final List<String> modifiedFiles;
  final Map<String, ProviderHealth> pluginStatus;
  final DateTime timestamp;

  const WorkspaceSnapshot({
    required this.metadata,
    required this.currentBranch,
    required this.modifiedFiles,
    required this.pluginStatus,
    required this.timestamp,
  });
}
