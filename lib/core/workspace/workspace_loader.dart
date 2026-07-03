import 'workspace.dart';
import 'workspace_manager.dart';

class WorkspaceLoader {
  final WorkspaceManager manager;

  WorkspaceLoader(this.manager);

  Future<Workspace> load(String rootPath) async {
    return await manager.openWorkspace(rootPath);
  }
}
