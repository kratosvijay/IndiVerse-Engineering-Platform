import 'dart:io';
import '../dto/api_response.dart';
import '../services/code_intelligence_service.dart';

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
}
