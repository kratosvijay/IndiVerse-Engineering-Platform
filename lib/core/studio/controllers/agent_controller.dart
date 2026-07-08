import 'dart:convert';
import 'dart:io';
import '../services/agent_service.dart';
import '../dto/api_response.dart';
import '../../agent/workflow/planner_context.dart';
import '../../agent/workflow/task_graph.dart';

class AgentController {
  final AgentService service;

  AgentController(this.service);

  Future<void> handlePlan(HttpRequest request, String requestId) async {
    try {
      final bodyStr = await utf8.decoder.bind(request).join();
      final bodyJson = jsonDecode(bodyStr) as Map<String, dynamic>;
      final context = PlannerContext.fromJson(bodyJson);

      final graph = await service.createPlan(context);

      final response = ApiResponse(
        success: true,
        timestamp: DateTime.now().toIso8601String(),
        requestId: requestId,
        data: graph.toJson(),
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

  Future<void> handleExecute(HttpRequest request, String requestId) async {
    try {
      final bodyStr = await utf8.decoder.bind(request).join();
      final bodyJson = jsonDecode(bodyStr) as Map<String, dynamic>;
      final graph =
          TaskGraph.fromJson(bodyJson['graph'] as Map<String, dynamic>);
      final workspaceId = bodyJson['workspaceId'] as String? ?? '';
      final conversationId = bodyJson['conversationId'] as String? ?? '';

      final session = await service.startExecution(
          graph, workspaceId, conversationId, requestId);

      final response = ApiResponse(
        success: true,
        timestamp: DateTime.now().toIso8601String(),
        requestId: requestId,
        data: session.toJson(),
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

  Future<void> handlePause(HttpRequest request, String requestId) async {
    try {
      final session = await service.pauseExecution();

      final response = ApiResponse(
        success: true,
        timestamp: DateTime.now().toIso8601String(),
        requestId: requestId,
        data: session.toJson(),
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

  Future<void> handleResume(HttpRequest request, String requestId) async {
    try {
      final bodyStr = await utf8.decoder.bind(request).join();
      final bodyJson = jsonDecode(bodyStr) as Map<String, dynamic>;
      final workspaceId = bodyJson['workspaceId'] as String? ?? '';
      final conversationId = bodyJson['conversationId'] as String? ?? '';

      final session =
          await service.resumeExecution(workspaceId, conversationId, requestId);

      final response = ApiResponse(
        success: true,
        timestamp: DateTime.now().toIso8601String(),
        requestId: requestId,
        data: session.toJson(),
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

  Future<void> handleRetry(HttpRequest request, String requestId) async {
    try {
      final bodyStr = await utf8.decoder.bind(request).join();
      final bodyJson = jsonDecode(bodyStr) as Map<String, dynamic>;
      final workspaceId = bodyJson['workspaceId'] as String? ?? '';
      final conversationId = bodyJson['conversationId'] as String? ?? '';

      final session =
          await service.retryExecution(workspaceId, conversationId, requestId);

      final response = ApiResponse(
        success: true,
        timestamp: DateTime.now().toIso8601String(),
        requestId: requestId,
        data: session.toJson(),
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

      if (service.getStatus()['activeWorkflowId'] == workflowId &&
          service.activeSession == null) {
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
        return;
      }

      final record = await service.cancelExecution();

      final response = ApiResponse(
        success: true,
        timestamp: DateTime.now().toIso8601String(),
        requestId: requestId,
        data: record.toJson(),
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
    final statusMap = service.getStatus();
    final active = service.activeSession;

    if (statusMap['activeWorkflowId'] != null && active == null) {
      final response = ApiResponse(
        success: true,
        timestamp: DateTime.now().toIso8601String(),
        requestId: requestId,
        data: statusMap,
      );
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write(response.toJsonString());
      return;
    }

    if (active != null) {
      final response = ApiResponse(
        success: true,
        timestamp: DateTime.now().toIso8601String(),
        requestId: requestId,
        data: active.toJson(),
      );
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write(response.toJsonString());
    } else {
      final response = ApiResponse(
        success: true,
        timestamp: DateTime.now().toIso8601String(),
        requestId: requestId,
        data: const {'status': 'idle'},
      );
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write(response.toJsonString());
    }
  }

  Future<void> handleHistory(HttpRequest request, String requestId) async {
    final history = service.history.map((s) => s.toJson()).toList();
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
