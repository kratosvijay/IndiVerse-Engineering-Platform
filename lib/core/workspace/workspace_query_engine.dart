import 'graph/workspace_symbol.dart';

class WorkspaceQueryResult<T> {
  final List<T> items;
  final int totalCount;
  final Duration elapsed;
  final bool truncated;

  const WorkspaceQueryResult({
    required this.items,
    required this.totalCount,
    required this.elapsed,
    this.truncated = false,
  });
}

abstract class WorkspaceQueryEngine {
  WorkspaceQueryResult<WorkspaceSymbol> findSymbol(String query);
  WorkspaceQueryResult<String> findReferences(String symbolName);
  WorkspaceQueryResult<WorkspaceSymbol> findImplementations(String className);
  WorkspaceQueryResult<String> findCallers(String methodName);
  WorkspaceQueryResult<String> findCallees(String methodName);
  WorkspaceQueryResult<String> findFiles(String globPattern);
  WorkspaceQueryResult<WorkspaceSymbol> findDefinition(String symbolName);
}
