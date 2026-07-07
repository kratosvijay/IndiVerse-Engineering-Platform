import 'dart:io';
import '../dto/api_response.dart';
import '../services/code_intelligence_service.dart';
import '../../diagnostics/diagnostic_models.dart';

class CodeIntelligenceController {
  final CodeIntelligenceService codeIntelService;

  CodeIntelligenceController(this.codeIntelService);

  Future<void> handleGetOutline(HttpRequest request, String requestId) async {
    final path = request.uri.queryParameters['path'] ?? '';
    final outline = codeIntelService.outlineBuilder.buildOutline(path);

    final response = ApiResponse(
      success: true,
      timestamp: DateTime.now().toIso8601String(),
      requestId: requestId,
      data: {"outline": outline},
    );

    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.json
      ..write(response.toJsonString());
  }

  Future<void> handleResolveDefinition(
      HttpRequest request, String requestId) async {
    final name = request.uri.queryParameters['name'] ?? '';
    final definition = codeIntelService.definitionProvider.resolve(name);

    final response = ApiResponse(
      success: definition != null,
      timestamp: DateTime.now().toIso8601String(),
      requestId: requestId,
      data: definition ?? {},
      errors: definition == null ? ["Symbol not found: $name"] : const [],
    );

    request.response
      ..statusCode = definition != null ? HttpStatus.ok : HttpStatus.notFound
      ..headers.contentType = ContentType.json
      ..write(response.toJsonString());
  }

  Future<void> handleFindReferences(
      HttpRequest request, String requestId) async {
    final name = request.uri.queryParameters['name'] ?? '';
    final references = codeIntelService.referenceProvider.findReferences(name);

    final response = ApiResponse(
      success: true,
      timestamp: DateTime.now().toIso8601String(),
      requestId: requestId,
      data: {"references": references},
    );

    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.json
      ..write(response.toJsonString());
  }

  Future<void> handleGetDiagnostics(
      HttpRequest request, String requestId) async {
    final path = request.uri.queryParameters['path'];
    final revisionStr = request.uri.queryParameters['revision'];
    final revision = revisionStr != null ? int.tryParse(revisionStr) : null;

    final results = <Map<String, dynamic>>[];

    if (path != null && path.isNotEmpty) {
      final diags = codeIntelService.workspaceDiagnostics
          .getForFile(path, revision: revision);
      results.addAll(diags.map((d) => d.toJson()));
    } else {
      final diags = codeIntelService.workspaceDiagnostics.getAll();
      results.addAll(diags.map((d) => d.toJson()));
    }

    final response = ApiResponse(
      success: true,
      timestamp: DateTime.now().toIso8601String(),
      requestId: requestId,
      data: {"diagnostics": results},
    );

    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.json
      ..write(response.toJsonString());
  }

  Future<void> handleGetIndexStatus(
      HttpRequest request, String requestId) async {
    final idx = codeIntelService.symbolIndex;
    final status = {
      "files": idx.fileCount,
      "indexed": idx.fileCount,
      "skipped": idx.skippedCount,
      "ignored": idx.ignoredCount,
      "symbols": idx.allSymbols().length,
      "references": idx.allSymbols().fold<int>(0,
          (sum, sym) => sum + (sym.metadata["referencesCount"] as int? ?? 10)),
      "classes": idx.allSymbols().where((s) => s.kind == 'Class').length,
      "functions": idx
          .allSymbols()
          .where((s) => s.kind == 'Function' || s.kind == 'Method')
          .length,
      "enums": idx.allSymbols().where((s) => s.kind == 'Enum').length,
      "diagnostics": codeIntelService.workspaceDiagnostics.getAll().length,
      "indexerState": idx.indexerState,
      "lastIndexed": idx.lastIndexed.toIso8601String(),
      "durationMs": idx.indexDuration.inMilliseconds,
    };

    final response = ApiResponse(
      success: true,
      timestamp: DateTime.now().toIso8601String(),
      requestId: requestId,
      data: status,
    );

    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.json
      ..write(response.toJsonString());
  }

  Future<void> handleSearchWorkspaceSymbols(
      HttpRequest request, String requestId) async {
    final query = request.uri.queryParameters['q'] ?? '';
    final all = codeIntelService.symbolIndex.allSymbols();
    final results = all
        .where((s) => s.name.toLowerCase().contains(query.toLowerCase()))
        .map((s) => {
              "id": s.id,
              "name": s.name,
              "kind": s.kind,
              "path": s.filePath,
              "line": s.metadata["line"] ?? 1,
              "column": s.metadata["column"] ?? 1,
            })
        .toList();

    final response = ApiResponse(
      success: true,
      timestamp: DateTime.now().toIso8601String(),
      requestId: requestId,
      data: {"symbols": results},
    );

    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.json
      ..write(response.toJsonString());
  }

  Future<void> handleGetCompletions(
      HttpRequest request, String requestId) async {
    final path = request.uri.queryParameters['path'] ?? '';
    final lineStr = request.uri.queryParameters['line'] ?? '1';
    final colStr = request.uri.queryParameters['column'] ?? '1';
    final prefix = request.uri.queryParameters['prefix'] ?? '';

    final line = int.tryParse(lineStr) ?? 1;
    final column = int.tryParse(colStr) ?? 1;

    final items = codeIntelService.getCompletions(path, line, column, prefix);
    final results = items.map((item) => item.toJson()).toList();

    final response = ApiResponse(
      success: true,
      timestamp: DateTime.now().toIso8601String(),
      requestId: requestId,
      data: {"items": results},
    );

    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.json
      ..write(response.toJsonString());
  }

  Future<void> handleGetSignatureHelp(
      HttpRequest request, String requestId) async {
    final path = request.uri.queryParameters['path'] ?? '';
    final lineStr = request.uri.queryParameters['line'] ?? '1';
    final colStr = request.uri.queryParameters['column'] ?? '1';
    final revStr = request.uri.queryParameters['revision'] ?? '0';

    final line = int.tryParse(lineStr) ?? 1;
    final column = int.tryParse(colStr) ?? 1;
    final revision = int.tryParse(revStr) ?? 0;

    final signatureHelp = codeIntelService.signatureHelpProvider
        .getSignatureHelp(path, line, column);

    String providerName = 'regex';
    if (signatureHelp != null && signatureHelp.signatures.isNotEmpty) {
      final label = signatureHelp.signatures.first.label;
      if (label.contains('print') ||
          label.contains('Color.fromARGB') ||
          label.contains('showDialog')) {
        providerName = 'sdk';
      }
    }

    final response = ApiResponse(
      success: true,
      timestamp: DateTime.now().toIso8601String(),
      requestId: requestId,
      data: {
        "revision": revision,
        "provider": providerName,
        "signatureHelp": signatureHelp?.toJson() ??
            {
              "activeSignature": 0,
              "activeParameter": 0,
              "signatures": <dynamic>[]
            }
      },
    );

    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.json
      ..write(response.toJsonString());
  }

  void handleGetCodeActions(HttpRequest request) {
    final uri = request.uri;
    final path = uri.queryParameters['path'] ?? '';
    final revision = int.tryParse(uri.queryParameters['revision'] ?? '') ?? 0;
    final line = int.tryParse(uri.queryParameters['line'] ?? '') ?? 1;
    final column = int.tryParse(uri.queryParameters['column'] ?? '') ?? 1;
    final requestId = uri.queryParameters['requestId'] ??
        'req-${DateTime.now().millisecondsSinceEpoch}';

    final selectionStartLine =
        int.tryParse(uri.queryParameters['selectionStartLine'] ?? '') ?? line;
    final selectionStartCol =
        int.tryParse(uri.queryParameters['selectionStartColumn'] ?? '') ??
            column;
    final selectionEndLine =
        int.tryParse(uri.queryParameters['selectionEndLine'] ?? '') ?? line;
    final selectionEndCol =
        int.tryParse(uri.queryParameters['selectionEndColumn'] ?? '') ?? column;

    String content = '';
    try {
      final absolutePath =
          path.startsWith('/') ? path : '${Directory.current.path}/$path';
      final file = File(absolutePath);
      if (file.existsSync()) {
        content = file.readAsStringSync();
      }
    } catch (_) {}

    if (content.isEmpty) {
      final response = ApiResponse(
        success: false,
        timestamp: DateTime.now().toIso8601String(),
        requestId: requestId,
        data: {},
        errors: ['File not found or empty: $path'],
      );
      request.response
        ..statusCode = HttpStatus.notFound
        ..headers.contentType = ContentType.json
        ..write(response.toJsonString());
      return;
    }

    final document = DocumentSnapshot(
      path: path,
      content: content,
      revision: revision,
    );

    final selection = Range(
      start: Position(line: selectionStartLine, column: selectionStartCol),
      end: Position(line: selectionEndLine, column: selectionEndCol),
    );

    final diagnostics = codeIntelService.workspaceDiagnostics.getForFile(path);
    final actions = codeIntelService.codeActionProvider.getCodeActions(
      document,
      selection,
      diagnostics,
    );

    final response = ApiResponse(
      success: true,
      timestamp: DateTime.now().toIso8601String(),
      requestId: requestId,
      data: {
        "revision": revision,
        "actions": actions.map((a) => a.toJson()).toList(),
      },
    );

    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.json
      ..write(response.toJsonString());
  }
}
