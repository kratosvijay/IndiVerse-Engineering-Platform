import 'dart:async';
import 'dart:io';
import '../../../platform_sdk/platform_sdk.dart';
import '../../knowledge/models/symbol.dart';
import '../../diagnostics/diagnostic_models.dart';
import '../../diagnostics/diagnostics_engine.dart';
import '../../diagnostics/completion_provider.dart';

class FileDiagnostics {
  final String path;
  final int revision;
  final List<Diagnostic> diagnostics;

  FileDiagnostics({
    required this.path,
    required this.revision,
    required this.diagnostics,
  });
}

class WorkspaceDiagnostics {
  final Map<String, FileDiagnostics> _files = {};

  List<Diagnostic> getForFile(String path, {int? revision}) {
    final fileDiag = _files[path];
    if (fileDiag == null) return [];
    if (revision != null && fileDiag.revision != revision) {
      return [];
    }
    return fileDiag.diagnostics;
  }

  List<Diagnostic> getAll() {
    return _files.values.expand((f) => f.diagnostics).toList();
  }

  void updateForFile(String path, int revision, List<Diagnostic> diagnostics) {
    _files[path] = FileDiagnostics(
      path: path,
      revision: revision,
      diagnostics: diagnostics,
    );
  }

  void removeFile(String path) {
    _files.remove(path);
  }
}

class CodeIntelligenceService {
  final PlatformSDK sdk;
  final SymbolIndex symbolIndex = SymbolIndex();
  final WorkspaceDiagnostics workspaceDiagnostics = WorkspaceDiagnostics();
  final DiagnosticsEngine diagnosticsEngine = DiagnosticsEngine();

  late final WorkspaceIndexer indexer;
  late final OutlineBuilder outlineBuilder;
  late final DefinitionProvider definitionProvider;
  late final ReferenceProvider referenceProvider;

  final List<String> _dirtyQueue = [];
  bool _isQueueProcessing = false;

  late final List<CompletionContributor> completionContributors;

  CodeIntelligenceService(this.sdk) {
    indexer = WorkspaceIndexer(this);
    outlineBuilder = OutlineBuilder(this);
    definitionProvider = DefinitionProvider(this);
    referenceProvider = ReferenceProvider();
    completionContributors = [
      KeywordContributor(),
      ScopeContributor(symbolIndex: symbolIndex),
      SnippetContributor(),
    ];
  }

  List<CompletionItem> getCompletions(
    String path,
    int line,
    int column,
    String prefix,
  ) {
    String content = '';
    try {
      final absolutePath =
          path.startsWith('/') ? path : '${Directory.current.path}/$path';
      final file = File(absolutePath);
      if (file.existsSync()) {
        content = file.readAsStringSync();
      }
    } catch (_) {}

    final doc = DocumentSnapshot(
      path: path,
      content: content,
      revision: 0,
    );

    final position = Position(line: line, column: column);
    final results = <CompletionItem>[];

    for (final contributor in completionContributors) {
      results.addAll(contributor.getCompletions(doc, position, prefix));
    }

    final seen = <String>{};
    final unique = <CompletionItem>[];
    for (final item in results) {
      if (!seen.contains(item.label)) {
        seen.add(item.label);
        unique.add(item);
      }
    }

    return unique;
  }

  Future<void> initialize() async {
    await indexer.indexWorkspace();
  }

  void handleFileChanged(String path) {
    indexer.indexFile(path);
    enqueueFileForDiagnostics(path);
  }

  void enqueueFileForDiagnostics(String path) {
    if (!_dirtyQueue.contains(path)) {
      _dirtyQueue.add(path);
    }
    _processDirtyQueue();
  }

  Future<void> _processDirtyQueue() async {
    if (_isQueueProcessing) return;
    _isQueueProcessing = true;

    while (_dirtyQueue.isNotEmpty) {
      final path = _dirtyQueue.removeAt(0);
      try {
        final file = File('${Directory.current.path}/$path');
        if (file.existsSync()) {
          final content = await file.readAsString();
          final doc = DocumentSnapshot(
            path: path,
            content: content,
            revision: 0,
          );
          final diags = diagnosticsEngine.run(doc);
          workspaceDiagnostics.updateForFile(path, 0, diags);
        } else {
          workspaceDiagnostics.removeFile(path);
        }
      } catch (_) {}
      await Future<void>.delayed(Duration.zero);
    }

    _isQueueProcessing = false;
  }
}

class SymbolIndex {
  final Map<String, List<SymbolModel>> _index = {};
  int skippedCount = 0;
  int ignoredCount = 0;
  DateTime lastIndexed = DateTime.now();
  Duration indexDuration = Duration.zero;
  String indexerState = "Ready";

  List<SymbolModel> getForFile(String path) => _index[path] ?? [];

  void updateForFile(String path, List<SymbolModel> symbols) {
    _index[path] = symbols;
  }

  void removeFile(String path) {
    _index.remove(path);
  }

  List<SymbolModel> allSymbols() {
    return _index.values.expand((list) => list).toList();
  }

  int get fileCount => _index.length;
}

class WorkspaceIndexer {
  final CodeIntelligenceService _service;

  WorkspaceIndexer(this._service);

  Future<void> indexWorkspace() async {
    final startTime = DateTime.now();
    _service.symbolIndex.indexerState = "Indexing";

    final rootDir = Directory(Directory.current.path);
    if (!rootDir.existsSync()) return;

    try {
      final list = rootDir.listSync(recursive: true);
      for (final entity in list) {
        if (entity is File) {
          final relPath =
              entity.path.replaceFirst('${Directory.current.path}/', '');
          if (_isIgnored(relPath)) {
            _service.symbolIndex.ignoredCount++;
            continue;
          }
          if (_isSupported(relPath)) {
            indexFile(relPath);
          } else {
            _service.symbolIndex.skippedCount++;
          }
        }
      }
    } catch (_) {}

    _service.symbolIndex.indexerState = "Ready";
    _service.symbolIndex.lastIndexed = DateTime.now();
    _service.symbolIndex.indexDuration = DateTime.now().difference(startTime);
  }

  void indexFile(String relativePath) {
    final file = File('${Directory.current.path}/$relativePath');
    if (!file.existsSync()) {
      _service.symbolIndex.removeFile(relativePath);
      _service.workspaceDiagnostics.removeFile(relativePath);
      return;
    }

    try {
      final content = file.readAsStringSync();
      final symbols = _parseSymbols(content, relativePath);
      _service.symbolIndex.updateForFile(relativePath, symbols);

      final doc = DocumentSnapshot(
        path: relativePath,
        content: content,
        revision: 0,
      );
      final diags = _service.diagnosticsEngine.run(doc);
      _service.workspaceDiagnostics.updateForFile(relativePath, 0, diags);
    } catch (_) {}
  }

  bool _isIgnored(String path) {
    return path.contains('.git/') ||
        path.contains('.dart_tool/') ||
        path.contains('build/') ||
        path.contains('node_modules/');
  }

  bool _isSupported(String path) {
    return path.endsWith('.dart') ||
        path.endsWith('.json') ||
        path.endsWith('.yaml') ||
        path.endsWith('.md');
  }

  List<SymbolModel> _parseSymbols(String content, String path) {
    final list = <SymbolModel>[];
    final lines = content.split('\n');

    final classRegex = RegExp(r'class\s+([A-Za-z0-9_]+)');
    final methodRegex = RegExp(r'^\s*([A-Za-z0-9_<>]+)\s+([A-Za-z0-9_]+)\s*\(');
    final fieldRegex = RegExp(
        r'^\s*(final|const|late|var)?\s*([A-Za-z0-9_<>]+)\s+([A-Za-z0-9_]+)\s*[;=]');

    String? currentClass;
    String? currentClassId;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final classMatch = classRegex.firstMatch(line);
      if (classMatch != null) {
        currentClass = classMatch.group(1)!;
        currentClassId = "$path-$currentClass";
        list.add(SymbolModel(
          id: currentClassId,
          name: currentClass,
          kind: "Class",
          filePath: path,
          metadata: {
            "line": i + 1,
            "column": line.indexOf(currentClass) + 1,
            "parentId": null,
            "deprecated": false,
            "tags": <String>[],
          },
        ));
        continue;
      }

      // Check if bracket closed class
      if (currentClass != null && line.trim() == '}') {
        currentClass = null;
        currentClassId = null;
        continue;
      }

      final methodMatch = methodRegex.firstMatch(line);
      if (methodMatch != null) {
        final name = methodMatch.group(2)!;
        list.add(SymbolModel(
          id: "$path-${currentClass ?? 'global'}-$name",
          name: name,
          kind: currentClass != null ? "Method" : "Function",
          filePath: path,
          metadata: {
            "line": i + 1,
            "column": line.indexOf(name) + 1,
            "parentId": currentClassId,
            "deprecated": false,
            "tags": <String>[],
          },
        ));
        continue;
      }

      final fieldMatch = fieldRegex.firstMatch(line);
      if (fieldMatch != null) {
        final name = fieldMatch.group(3)!;
        list.add(SymbolModel(
          id: "$path-${currentClass ?? 'global'}-$name",
          name: name,
          kind: "Variable",
          filePath: path,
          metadata: {
            "line": i + 1,
            "column": line.indexOf(name) + 1,
            "parentId": currentClassId,
            "deprecated": false,
            "tags": <String>[],
          },
        ));
      }
    }
    return list;
  }
}

class OutlineBuilder {
  final CodeIntelligenceService _service;

  OutlineBuilder(this._service);

  List<Map<String, dynamic>> buildOutline(String path) {
    final symbols = _service.symbolIndex.getForFile(path);
    final outline = <Map<String, dynamic>>[];
    final map = <String, Map<String, dynamic>>{};

    for (final sym in symbols) {
      final item = {
        "id": sym.id,
        "name": sym.name,
        "kind": sym.kind,
        "path": sym.filePath,
        "line": sym.metadata["line"] ?? 1,
        "column": sym.metadata["column"] ?? 1,
        "deprecated": sym.metadata["deprecated"] ?? false,
        "children": <Map<String, dynamic>>[],
      };
      map[sym.id] = item;

      final parentId = sym.metadata["parentId"];
      if (parentId != null && map.containsKey(parentId)) {
        (map[parentId]!["children"] as List).add(item);
      } else {
        outline.add(item);
      }
    }
    return outline;
  }
}

class DefinitionProvider {
  final CodeIntelligenceService _service;

  DefinitionProvider(this._service);

  Map<String, dynamic>? resolve(String name) {
    final symbols = _service.symbolIndex.allSymbols();
    for (final sym in symbols) {
      if (sym.name == name) {
        return {
          "id": sym.id,
          "name": sym.name,
          "path": sym.filePath,
          "line": sym.metadata["line"] ?? 1,
          "column": sym.metadata["column"] ?? 1,
        };
      }
    }
    return null;
  }
}

class ReferenceProvider {
  ReferenceProvider();

  List<Map<String, dynamic>> findReferences(String name) {
    final references = <Map<String, dynamic>>[];
    final rootDir = Directory(Directory.current.path);
    if (!rootDir.existsSync()) return references;

    try {
      final list = rootDir.listSync(recursive: true);
      for (final entity in list) {
        if (entity is File && entity.path.endsWith('.dart')) {
          final relPath =
              entity.path.replaceFirst('${Directory.current.path}/', '');
          final content = entity.readAsStringSync();
          final lines = content.split('\n');
          for (var i = 0; i < lines.length; i++) {
            final line = lines[i];
            // Simple match boundary checker
            if (line.contains(RegExp('\\b$name\\b'))) {
              references.add({
                "path": relPath,
                "line": i + 1,
                "snippet": line.trim(),
              });
            }
          }
        }
      }
    } catch (_) {}

    return references;
  }
}
