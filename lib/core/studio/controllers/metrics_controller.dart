import 'dart:io';
import '../services/metrics_service.dart';
import '../dto/api_response.dart';

class MetricsController {
  final MetricsService service;

  MetricsController(this.service);

  Future<void> handleGetMetrics(HttpRequest request, String requestId) async {
    try {
      final data = await service.getMetricsSnapshot();

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
        ..statusCode = HttpStatus.internalServerError
        ..headers.contentType = ContentType.json
        ..write(response.toJsonString());
    }
  }
}
