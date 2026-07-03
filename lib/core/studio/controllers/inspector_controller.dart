import 'dart:io';
import '../services/inspector_service.dart';
import '../dto/api_response.dart';

class InspectorController {
  final InspectorService service;

  InspectorController(this.service);

  Future<void> handleInspect(HttpRequest request, String requestId) async {
    try {
      final id = request.uri.queryParameters['id'] ?? '';
      final type = request.uri.queryParameters['type'] ?? '';

      if (id.isEmpty || type.isEmpty) {
        throw Exception("Both 'id' and 'type' parameters are required");
      }

      final data = await service.inspect(id: id, type: type);

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
        ..statusCode = HttpStatus.badRequest
        ..headers.contentType = ContentType.json
        ..write(response.toJsonString());
    }
  }
}
