import 'dart:convert';
import 'dart:io';
import '../services/agent_service.dart';
import '../dto/api_response.dart';

class AgentController {
  final AgentService service;

  AgentController(this.service);

  Future<void> handleRun(HttpRequest request, String requestId) async {
    try {
      var name = "Planner";
      if (request.contentLength > 0) {
        final bodyStr = await utf8.decoder.bind(request).join();
        if (bodyStr.isNotEmpty) {
          final bodyJson = jsonDecode(bodyStr) as Map<String, dynamic>;
          name = bodyJson["name"] as String? ?? "Planner";
        }
      }

      final record = await service.runWorkflow(name);

      final response = ApiResponse(
        success: true,
        timestamp: DateTime.now().toIso8601String(),
        requestId: requestId,
        data: record,
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

  Future<void> handleCancel(HttpRequest request, String requestId) async {
    try {
      var workflowId = "";
      if (request.contentLength > 0) {
        final bodyStr = await utf8.decoder.bind(request).join();
        if (bodyStr.isNotEmpty) {
          final bodyJson = jsonDecode(bodyStr) as Map<String, dynamic>;
          workflowId = bodyJson["workflowId"] as String? ?? "";
        }
      }

      final record = await service.cancelWorkflow(workflowId);

      final response = ApiResponse(
        success: true,
        timestamp: DateTime.now().toIso8601String(),
        requestId: requestId,
        data: record,
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

  Future<void> handleStatus(HttpRequest request, String requestId) async {
    final data = service.getStatus();
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

  Future<void> handleHistory(HttpRequest request, String requestId) async {
    final history = service.getHistory();
    final response = ApiResponse(
      success: true,
      timestamp: DateTime.now().toIso8601String(),
      requestId: requestId,
      data: {"history": history},
    );
    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.json
      ..write(response.toJsonString());
  }

  Future<void> handleWorkflows(HttpRequest request, String requestId) async {
    final list = service.getAvailableWorkflows();
    final response = ApiResponse(
      success: true,
      timestamp: DateTime.now().toIso8601String(),
      requestId: requestId,
      data: {"workflows": list},
    );
    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.json
      ..write(response.toJsonString());
  }
}
