import 'dart:convert';
import 'workspace.dart';

class WorkspaceDiagnostics {
  final Workspace workspace;

  WorkspaceDiagnostics(this.workspace);

  String exportJson() {
    return jsonEncode({
      "id": workspace.id,
      "name": workspace.name,
      "rootPath": workspace.rootPath,
      "projectTypes": workspace.projectTypes,
      "metadata": {
        "projectName": workspace.metadata.projectName,
        "language": workspace.metadata.primaryLanguage,
        "rulesCount": workspace.metadata.rules.length,
        "adrsCount": workspace.metadata.adrs.length,
      }
    });
  }

  String exportMarkdown() {
    return """
# Workspace Diagnostics - ${workspace.name}
- **Root Path**: ${workspace.rootPath}
- **Detected Types**: ${workspace.projectTypes.join(', ')}
- **Rules Count**: ${workspace.metadata.rules.length}
- **ADRs Count**: ${workspace.metadata.adrs.length}
""";
  }

  String exportSummary() {
    return "Workspace: ${workspace.name} [${workspace.projectTypes.join(', ')}]";
  }
}
