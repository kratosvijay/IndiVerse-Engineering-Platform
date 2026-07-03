import 'dart:io';
import '../services/workspace_service.dart';
import '../dto/api_response.dart';

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
}
