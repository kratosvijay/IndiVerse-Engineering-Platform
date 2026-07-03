import '../workspace_context.dart';

class WorkspaceProvider implements ContextProvider {
  @override
  Future<List<ContextContribution>> build(String rootPath) async {
    return [
      ContextContribution(
        providerId: "workspace",
        content: "Workspace root initialized: $rootPath",
        tokens: 5,
        priority: 50,
        sourcePath: rootPath,
      )
    ];
  }
}
