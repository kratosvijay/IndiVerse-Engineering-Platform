import '../../../context/context_engine.dart';
import '../../workspace_intelligence.dart';

class ArchitectureContextProvider implements ContextProvider {
  @override
  final String id = 'architecture';

  @override
  Future<ContextFragment> resolve(ContextRequest request) async {
    final intel = WorkspaceIntelligenceRegistry.active;
    final content = StringBuffer();

    if (intel != null) {
      final snapshot = intel.getSnapshot();
      content.writeln("=== Project Architecture ===");
      content.writeln("Services:");
      for (final s in snapshot.services) {
        content.writeln("  - ${s.name} (${s.filePath})");
      }
      content.writeln("Providers:");
      for (final p in snapshot.providers) {
        content.writeln("  - ${p.name} (${p.filePath})");
      }
      content.writeln("Routes:");
      for (final r in snapshot.routes) {
        content.writeln("  - ${r.name} (${r.filePath})");
      }
    } else {
      content.writeln("Project Architecture Context: Workspace not loaded.");
    }

    final txt = content.toString();
    return ContextFragment(
      source: id,
      content: txt,
      estimatedTokens: (txt.length / 4.0).ceil(),
      priority: ContextPriority.architecture,
      providerId: 'context.architecture',
      version: '1.0.0',
      cacheable: true,
    );
  }
}

class SymbolGraphContextProvider implements ContextProvider {
  @override
  final String id = 'symbolGraph';

  @override
  Future<ContextFragment> resolve(ContextRequest request) async {
    final intel = WorkspaceIntelligenceRegistry.active;
    final content = StringBuffer();

    if (intel != null) {
      final snapshot = intel.getSnapshot();
      content.writeln("=== Symbol Graph Snapshot (V${snapshot.version}) ===");
      content.writeln("Total Symbols: ${snapshot.symbols.length}");

      // List primary classes and structures
      final topClasses = snapshot.classes.take(15).toList();
      for (final cls in topClasses) {
        content.writeln("Class: ${cls.name} (${cls.filePath})");
        if (cls.childrenIds.isNotEmpty) {
          content.writeln(
              "  Children: ${cls.childrenIds.map((id) => id.split('.').last).join(', ')}");
        }
      }
      if (snapshot.classes.length > 15) {
        content
            .writeln("... and ${snapshot.classes.length - 15} more classes.");
      }
    } else {
      content.writeln("Symbol Graph Context: Workspace not loaded.");
    }

    final txt = content.toString();
    return ContextFragment(
      source: id,
      content: txt,
      estimatedTokens: (txt.length / 4.0).ceil(),
      priority: ContextPriority.symbolGraph,
      providerId: 'context.symbolGraph',
      version: '1.0.0',
      cacheable: true,
    );
  }
}

class DependencyContextProvider implements ContextProvider {
  @override
  final String id = 'dependencyGraph';

  @override
  Future<ContextFragment> resolve(ContextRequest request) async {
    final intel = WorkspaceIntelligenceRegistry.active;
    final content = StringBuffer();

    if (intel != null) {
      final snapshot = intel.getSnapshot();
      content.writeln("=== Dependency Import Graph ===");
      for (final dep in snapshot.dependencies.take(20)) {
        content
            .writeln("  ${dep.fromPath} -> ${dep.toPath} (${dep.type.name})");
      }
      if (snapshot.dependencies.length > 20) {
        content.writeln(
            "  ... and ${snapshot.dependencies.length - 20} more edges.");
      }
    } else {
      content.writeln("Dependency Graph Context: Workspace not loaded.");
    }

    final txt = content.toString();
    return ContextFragment(
      source: id,
      content: txt,
      estimatedTokens: (txt.length / 4.0).ceil(),
      priority: ContextPriority.dependencyGraph,
      providerId: 'context.dependencyGraph',
      version: '1.0.0',
      cacheable: true,
    );
  }
}

class CallGraphContextProvider implements ContextProvider {
  @override
  final String id = 'callGraph';

  @override
  Future<ContextFragment> resolve(ContextRequest request) async {
    final intel = WorkspaceIntelligenceRegistry.active;
    final content = StringBuffer();

    if (intel != null) {
      final snapshot = intel.getSnapshot();
      content.writeln("=== Invocations & Call Trees ===");
      for (final call in snapshot.calls.take(20)) {
        content.writeln(
            "  ${call.callerId.split('#').last} calls ${call.calleeId.split('#').last} (${call.type.name})");
      }
      if (snapshot.calls.length > 20) {
        content.writeln("  ... and ${snapshot.calls.length - 20} more calls.");
      }
    } else {
      content.writeln("Call Graph Context: Workspace not loaded.");
    }

    final txt = content.toString();
    return ContextFragment(
      source: id,
      content: txt,
      estimatedTokens: (txt.length / 4.0).ceil(),
      priority: ContextPriority.callGraph,
      providerId: 'context.callGraph',
      version: '1.0.0',
      cacheable: true,
    );
  }
}

class BuildContextProvider implements ContextProvider {
  @override
  final String id = 'build';

  @override
  Future<ContextFragment> resolve(ContextRequest request) async {
    final intel = WorkspaceIntelligenceRegistry.active;
    final content = StringBuffer();

    if (intel != null) {
      final buildIntel = intel.buildIntelligence;
      content.writeln("=== Build & Test Intelligence ===");
      content.writeln(
          "Build status: ${buildIntel.hasBuildFailures ? 'FAILING' : 'PASSING'}");

      final errors = buildIntel.getErrors();
      if (errors.isNotEmpty) {
        content.writeln("Errors (${errors.length}):");
        for (final err in errors) {
          content.writeln(
              "  [${err.origin.name}] ${err.filePath ?? 'Global'}:${err.line ?? 0}:${err.column ?? 0} - ${err.message}");
        }
      } else {
        content.writeln("No compiler or analyzer errors registered.");
      }

      if (buildIntel.compilerOutput != null) {
        content.writeln(
            "Compiler Output snippet:\n${buildIntel.compilerOutput!.split('\n').take(10).join('\n')}");
      }
    } else {
      content.writeln("Build Context: Workspace not loaded.");
    }

    final txt = content.toString();
    return ContextFragment(
      source: id,
      content: txt,
      estimatedTokens: (txt.length / 4.0).ceil(),
      priority: ContextPriority.build,
      providerId: 'context.build',
      version: '1.0.0',
      cacheable: false,
    );
  }
}
