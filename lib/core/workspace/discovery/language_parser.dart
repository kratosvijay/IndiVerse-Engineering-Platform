import '../graph/workspace_symbol.dart';
import '../index/build_intelligence.dart';

class WorkspaceParseResult {
  final List<WorkspaceSymbol> symbols;
  final List<Map<String, dynamic>>
      imports; // List of {'target': String, 'type': DependencyType}
  final List<Map<String, dynamic>>
      calls; // List of {'callerId': String, 'calleeId': String, 'type': CallType}
  final List<BuildDiagnostic> diagnostics;

  const WorkspaceParseResult({
    required this.symbols,
    required this.imports,
    required this.calls,
    required this.diagnostics,
  });
}

abstract class LanguageParser {
  WorkspaceParseResult parse(String filePath, String content);
}
