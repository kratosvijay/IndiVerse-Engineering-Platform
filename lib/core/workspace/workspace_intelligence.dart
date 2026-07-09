import 'graph/workspace_symbol.dart';
import 'graph/dependency_graph.dart';
import 'graph/call_graph.dart';
import 'graph/workspace_snapshot.dart';
import 'index/architecture_index.dart';
import 'index/build_intelligence.dart';
import 'discovery/language_parser.dart';
import 'discovery/dart_regex_parser.dart';
import 'workspace_query_engine.dart';

class WorkspaceIntelligence implements WorkspaceQueryEngine {
  final String workspaceId;
  final String workspacePath;
  final LanguageParser parser;

  final Map<String, WorkspaceSymbol> _symbolsMap = {};
  final DependencyGraph _dependencyGraph = DependencyGraph();
  final CallGraph _callGraph = CallGraph();
  final ArchitectureIndex _architectureIndex = ArchitectureIndex();
  final BuildIntelligence _buildIntelligence = BuildIntelligence();
  final Map<String, String> _fileHashes = {};

  int _snapshotVersion = 1;

  WorkspaceIntelligence({
    required this.workspaceId,
    required this.workspacePath,
    LanguageParser? parser,
  }) : parser = parser ?? DartRegexParser();

  // Incremental Indexing: Re-indexes file if hash changes. Returns true if modified.
  bool indexFile(String filePath, String content) {
    final newHash = _calculateHash(content);
    final oldHash = _fileHashes[filePath];
    if (newHash == oldHash) {
      return false; // Skip parsing
    }

    _fileHashes[filePath] = newHash;
    _removeFileIndices(filePath);

    final parseResult = parser.parse(filePath, content);

    for (final sym in parseResult.symbols) {
      _symbolsMap[sym.id] = sym;
      _architectureIndex.indexSymbol(sym);
    }

    for (final imp in parseResult.imports) {
      _dependencyGraph.addDependency(
          filePath, imp['target'] as String, imp['type'] as DependencyType);
    }

    for (final call in parseResult.calls) {
      _callGraph.addCall(call['callerId'] as String, call['calleeId'] as String,
          call['type'] as CallType);
    }

    _snapshotVersion++;
    return true;
  }

  void removeFile(String filePath) {
    _fileHashes.remove(filePath);
    _removeFileIndices(filePath);
    _snapshotVersion++;
  }

  void _removeFileIndices(String filePath) {
    _symbolsMap.removeWhere((id, sym) => sym.filePath == filePath);
    _dependencyGraph.removeDependenciesForFile(filePath);
    _callGraph.removeCallsForFile(filePath);
    _architectureIndex.removeSymbolsForFile(filePath);
  }

  void clear() {
    _symbolsMap.clear();
    _dependencyGraph.clear();
    _callGraph.clear();
    _architectureIndex.clear();
    _buildIntelligence.clear();
    _fileHashes.clear();
    _snapshotVersion = 1;
  }

  // Build intelligence logs hook
  BuildIntelligence get buildIntelligence => _buildIntelligence;

  // Retrieve an immutable point-in-time snapshot of the workspace
  WorkspaceSnapshot getSnapshot() {
    final symList = List<WorkspaceSymbol>.unmodifiable(_symbolsMap.values);

    final depsList = <ImportEdge>[];
    for (final sym in symList) {
      depsList.addAll(_dependencyGraph.getEdges(sym.filePath));
    }
    final uniqueDeps = List<ImportEdge>.unmodifiable(depsList.toSet());

    final callsList = <CallEdge>[];
    for (final sym in symList) {
      callsList.addAll(_callGraph.getOutgoingCalls(sym.id));
    }
    final uniqueCalls = List<CallEdge>.unmodifiable(callsList.toSet());

    return WorkspaceSnapshot(
      snapshotId: "snapshot-$workspaceId-$_snapshotVersion",
      version: _snapshotVersion,
      createdAt: DateTime.now(),
      workspaceHash: _calculateHash(symList.map((s) => s.id).join(',')),
      symbols: symList,
      dependencies: uniqueDeps,
      calls: uniqueCalls,
      buildDiagnostics: _buildIntelligence.diagnostics,
      classes: _architectureIndex.classes,
      enums: _architectureIndex.enums,
      mixins: _architectureIndex.mixins,
      typedefs: _architectureIndex.typedefs,
      extensions: _architectureIndex.extensions,
      routes: _architectureIndex.routes,
      services: _architectureIndex.services,
      providers: _architectureIndex.providers,
    );
  }

  // --- WorkspaceQueryEngine Implementation ---

  @override
  WorkspaceQueryResult<WorkspaceSymbol> findSymbol(String query) {
    final watch = Stopwatch()..start();
    final lowerQuery = query.toLowerCase();

    final matches = _symbolsMap.values
        .where((s) => s.name.toLowerCase().contains(lowerQuery))
        .toList();

    watch.stop();
    return WorkspaceQueryResult(
      items: matches.take(50).toList(),
      totalCount: matches.length,
      elapsed: watch.elapsed,
      truncated: matches.length > 50,
    );
  }

  @override
  WorkspaceQueryResult<String> findReferences(String symbolName) {
    final watch = Stopwatch()..start();

    // Find all calls or symbols containing reference to symbolName
    final matches = <String>{};

    // Exact symbol check
    for (final sym in _symbolsMap.values) {
      if (sym.id.endsWith('#$symbolName') || sym.id.contains('#$symbolName.')) {
        matches.add(sym.filePath);
      }
    }

    // Call check
    _symbolsMap.values.forEach((sym) {
      final outgoing = _callGraph.getOutgoingCalls(sym.id);
      for (final call in outgoing) {
        if (call.calleeId.contains(symbolName)) {
          matches.add(sym.filePath);
        }
      }
    });

    watch.stop();
    final itemsList = matches.toList();
    return WorkspaceQueryResult(
      items: itemsList.take(50).toList(),
      totalCount: itemsList.length,
      elapsed: watch.elapsed,
      truncated: itemsList.length > 50,
    );
  }

  @override
  WorkspaceQueryResult<WorkspaceSymbol> findImplementations(String className) {
    final watch = Stopwatch()..start();

    // Find classes inheriting or implementing className
    final matches = _symbolsMap.values
        .where((s) =>
            s.kind == SymbolKind.classSymbol &&
            s.parentIds.any((pId) => pId.endsWith('#$className')))
        .toList();

    watch.stop();
    return WorkspaceQueryResult(
      items: matches.take(50).toList(),
      totalCount: matches.length,
      elapsed: watch.elapsed,
      truncated: matches.length > 50,
    );
  }

  @override
  WorkspaceQueryResult<String> findCallers(String methodName) {
    final watch = Stopwatch()..start();

    // Find call target
    final callers = <String>{};
    _symbolsMap.values.forEach((sym) {
      if (sym.name == methodName) {
        final incoming = _callGraph.getCallers(sym.id);
        callers.addAll(incoming);
      }
    });

    watch.stop();
    final callersList = callers.toList();
    return WorkspaceQueryResult(
      items: callersList.take(50).toList(),
      totalCount: callersList.length,
      elapsed: watch.elapsed,
      truncated: callersList.length > 50,
    );
  }

  @override
  WorkspaceQueryResult<String> findCallees(String methodName) {
    final watch = Stopwatch()..start();

    // Find targets called by methodName
    final callees = <String>{};
    _symbolsMap.values.forEach((sym) {
      if (sym.name == methodName) {
        final outgoing = _callGraph.getCallees(sym.id);
        callees.addAll(outgoing);
      }
    });

    watch.stop();
    final calleesList = callees.toList();
    return WorkspaceQueryResult(
      items: calleesList.take(50).toList(),
      totalCount: calleesList.length,
      elapsed: watch.elapsed,
      truncated: calleesList.length > 50,
    );
  }

  @override
  WorkspaceQueryResult<String> findFiles(String globPattern) {
    final watch = Stopwatch()..start();

    final pattern = globPattern.replaceAll('*', '.*');
    final regex = RegExp(pattern, caseSensitive: false);

    final matches =
        _fileHashes.keys.where((path) => regex.hasMatch(path)).toList();

    watch.stop();
    return WorkspaceQueryResult(
      items: matches.take(50).toList(),
      totalCount: matches.length,
      elapsed: watch.elapsed,
      truncated: matches.length > 50,
    );
  }

  @override
  WorkspaceQueryResult<WorkspaceSymbol> findDefinition(String symbolName) {
    final watch = Stopwatch()..start();

    WorkspaceSymbol? match;
    for (final sym in _symbolsMap.values) {
      if (sym.name == symbolName) {
        match = sym;
        break;
      }
    }

    watch.stop();
    return WorkspaceQueryResult(
      items: match != null ? [match] : const [],
      totalCount: match != null ? 1 : 0,
      elapsed: watch.elapsed,
      truncated: false,
    );
  }

  // DJB2 String Hash implementation
  String _calculateHash(String text) {
    var hash = 5381;
    for (var i = 0; i < text.length; i++) {
      hash = ((hash << 5) + hash) + text.codeUnitAt(i);
      hash = hash & 0xFFFFFFFF; // force 32-bit int
    }
    return hash.toRadixString(16);
  }
}

class WorkspaceIntelligenceRegistry {
  static final Map<String, WorkspaceIntelligence> _instances = {};
  static String? _activePath;

  static void register(String rootPath, WorkspaceIntelligence intel) {
    _instances[rootPath] = intel;
    _activePath ??= rootPath;
  }

  static void setActive(String rootPath) {
    _activePath = rootPath;
  }

  static void clearActive() {
    _activePath = null;
  }

  static WorkspaceIntelligence? get(String rootPath) => _instances[rootPath];

  static WorkspaceIntelligence? get active {
    if (_activePath != null) {
      return _instances[_activePath];
    }
    if (_instances.isNotEmpty) {
      return _instances.values.first;
    }
    return null;
  }

  static void clear() {
    _instances.clear();
    _activePath = null;
  }
}
