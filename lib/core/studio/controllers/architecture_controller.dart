import 'dart:io';
import '../services/architecture_service.dart';
import '../dto/api_response.dart';

class ArchitectureController {
  final ArchitectureService service;

  ArchitectureController(this.service);

  Future<void> handleGetTopology(HttpRequest request, String requestId) async {
    final data = service.getTopology();
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
  }

  Future<void> handleGetNodeDetails(
      HttpRequest request, String requestId) async {
    try {
      final nodeId = request.uri.queryParameters['id'] ?? '';
      if (nodeId.isEmpty) {
        throw Exception("Node ID parameter 'id' is required");
      }

      final data = service.getNodeDetails(nodeId);

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
