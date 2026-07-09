import 'workspace_symbol.dart';
import 'dependency_graph.dart';
import 'call_graph.dart';
import '../index/build_intelligence.dart';

class WorkspaceSnapshot {
  final String snapshotId;
  final int version;
  final DateTime createdAt;
  final String workspaceHash;

  final List<WorkspaceSymbol> symbols;
  final List<ImportEdge> dependencies;
  final List<CallEdge> calls;
  final List<BuildDiagnostic> buildDiagnostics;

  // Pre-grouped lists matching ArchitectureIndex categories for instant context gathering
  final List<WorkspaceSymbol> classes;
  final List<WorkspaceSymbol> enums;
  final List<WorkspaceSymbol> mixins;
  final List<WorkspaceSymbol> typedefs;
  final List<WorkspaceSymbol> extensions;
  final List<WorkspaceSymbol> routes;
  final List<WorkspaceSymbol> services;
  final List<WorkspaceSymbol> providers;

  const WorkspaceSnapshot({
    required this.snapshotId,
    required this.version,
    required this.createdAt,
    required this.workspaceHash,
    required this.symbols,
    required this.dependencies,
    required this.calls,
    required this.buildDiagnostics,
    required this.classes,
    required this.enums,
    required this.mixins,
    required this.typedefs,
    required this.extensions,
    required this.routes,
    required this.services,
    required this.providers,
  });

  Map<String, dynamic> toJson() => {
        'snapshotId': snapshotId,
        'version': version,
        'createdAt': createdAt.toIso8601String(),
        'workspaceHash': workspaceHash,
        'symbolsCount': symbols.length,
        'dependenciesCount': dependencies.length,
        'callsCount': calls.length,
        'buildDiagnosticsCount': buildDiagnostics.length,
      };
}
