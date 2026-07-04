import 'dart:io';
import '../services/workspace_service.dart';
import '../dto/api_response.dart';
import 'dart:convert';

class WorkspaceController {
  final WorkspaceService service;

  WorkspaceController(this.service);

  Future<void> handleGetWorkspace(HttpRequest request, String requestId) async {
    try {
      final path = request.uri.queryParameters['path'];
      final recursiveParam = request.uri.queryParameters['recursive'] ?? 'true';
      final recursive = recursiveParam.toLowerCase() == 'true';

      final data =
          await service.getWorkspaceTree(path: path, recursive: recursive);

      final response = ApiResponse(
        success: true,
        timestamp: DateTime.now().toIso8601String(),
        requestId: requestId,
        data: data,
      );

      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write(response.toJsonString());
    } catch (e) {
      final response = ApiResponse(
        success: false,
        timestamp: DateTime.now().toIso8601String(),
        requestId: requestId,
        data: const {},
        errors: [e.toString()],
      );
      request.response
        ..statusCode = HttpStatus.notFound
        ..headers.contentType = ContentType.json
        ..write(response.toJsonString());
    }
  }

  Future<void> handleGetFileContent(
      HttpRequest request, String requestId) async {
    try {
      final path = request.uri.queryParameters['path'] ?? '';
      final data = await service.getFileContent(path);

      final response = ApiResponse(
        success: true,
        timestamp: DateTime.now().toIso8601String(),
        requestId: requestId,
        data: data,
      );

      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write(response.toJsonString());
    } catch (e) {
      final response = ApiResponse(
        success: false,
        timestamp: DateTime.now().toIso8601String(),
        requestId: requestId,
        data: const {},
        errors: [e.toString()],
      );
      request.response
        ..statusCode = HttpStatus.notFound
        ..headers.contentType = ContentType.json
        ..write(response.toJsonString());
    }
  }

  Future<void> handleStat(HttpRequest request, String requestId) async {
    try {
      final path = request.uri.queryParameters['path'] ?? '';
      final data = await service.getStat(path);

      final response = ApiResponse(
        success: true,
        timestamp: DateTime.now().toIso8601String(),
        requestId: requestId,
        data: data,
      );

      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write(response.toJsonString());
    } catch (e) {
      final response = ApiResponse(
        success: false,
        timestamp: DateTime.now().toIso8601String(),
        requestId: requestId,
        data: const {},
        errors: [e.toString()],
      );
      request.response
        ..statusCode = HttpStatus.notFound
        ..headers.contentType = ContentType.json
        ..write(response.toJsonString());
    }
  }

  Future<void> handleSaveFile(HttpRequest request, String requestId) async {
    try {
      final path = request.uri.queryParameters['path'] ?? '';
      final bodyStr = await utf8.decoder.bind(request).join();
      final bodyJson = jsonDecode(bodyStr);
      final String content = bodyJson['content'] as String? ?? '';

      await service.saveFile(path, content);

      final response = ApiResponse(
        success: true,
        timestamp: DateTime.now().toIso8601String(),
        requestId: requestId,
        data: const {"status": "saved"},
      );

      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write(response.toJsonString());
    } catch (e) {
      final response = ApiResponse(
        success: false,
        timestamp: DateTime.now().toIso8601String(),
        requestId: requestId,
        data: const {},
        errors: [e.toString()],
      );
      request.response
        ..statusCode = HttpStatus.internalServerError
        ..headers.contentType = ContentType.json
        ..write(response.toJsonString());
    }
  }

  Future<void> handleCreateFile(HttpRequest request, String requestId) async {
    try {
      final path = request.uri.queryParameters['path'] ?? '';
      final bodyStr = await utf8.decoder.bind(request).join();
      final String content = bodyStr.isNotEmpty
          ? (jsonDecode(bodyStr)['content'] as String? ?? '')
          : '';

      await service.createFile(path, content);

      final response = ApiResponse(
        success: true,
        timestamp: DateTime.now().toIso8601String(),
        requestId: requestId,
        data: const {"status": "created"},
      );

      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write(response.toJsonString());
    } catch (e) {
      final response = ApiResponse(
        success: false,
        timestamp: DateTime.now().toIso8601String(),
        requestId: requestId,
        data: const {},
        errors: [e.toString()],
      );
      request.response
        ..statusCode = HttpStatus.internalServerError
        ..headers.contentType = ContentType.json
        ..write(response.toJsonString());
    }
  }

  Future<void> handleRenameFile(HttpRequest request, String requestId) async {
    try {
      final bodyStr = await utf8.decoder.bind(request).join();
      final bodyJson = jsonDecode(bodyStr);
      final String path = bodyJson['path'] as String? ?? '';
      final String newPath = bodyJson['newPath'] as String? ?? '';

      await service.renameFile(path, newPath);

      final response = ApiResponse(
        success: true,
        timestamp: DateTime.now().toIso8601String(),
        requestId: requestId,
        data: const {"status": "renamed"},
      );

      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write(response.toJsonString());
    } catch (e) {
      final response = ApiResponse(
        success: false,
        timestamp: DateTime.now().toIso8601String(),
        requestId: requestId,
        data: const {},
        errors: [e.toString()],
      );
      request.response
        ..statusCode = HttpStatus.internalServerError
        ..headers.contentType = ContentType.json
        ..write(response.toJsonString());
    }
  }

  Future<void> handleDeleteFile(HttpRequest request, String requestId) async {
    try {
      final path = request.uri.queryParameters['path'] ?? '';

      await service.deleteFile(path);

      final response = ApiResponse(
        success: true,
        timestamp: DateTime.now().toIso8601String(),
        requestId: requestId,
        data: const {"status": "deleted"},
      );

      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write(response.toJsonString());
    } catch (e) {
      final response = ApiResponse(
        success: false,
        timestamp: DateTime.now().toIso8601String(),
        requestId: requestId,
        data: const {},
        errors: [e.toString()],
      );
      request.response
        ..statusCode = HttpStatus.internalServerError
        ..headers.contentType = ContentType.json
        ..write(response.toJsonString());
    }
  }
}
