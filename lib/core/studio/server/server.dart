import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../../platform_sdk/platform_sdk.dart';
import '../../events/event_bus.dart';
import '../controllers/agent_controller.dart';
import '../controllers/architecture_controller.dart';
import '../controllers/inspector_controller.dart';
import '../controllers/metrics_controller.dart';
import '../controllers/search_controller.dart';
import '../controllers/workspace_controller.dart';
import '../dto/api_response.dart';
import '../middleware/error_handler.dart';
import '../middleware/request_logger.dart';
import '../services/agent_service.dart';
import '../services/architecture_service.dart';
import '../services/inspector_service.dart';
import '../services/metrics_service.dart';
import '../services/search_service.dart';
import '../services/workspace_service.dart';
import '../controllers/code_intelligence_controller.dart';
import '../services/code_intelligence_service.dart';
import '../websocket/websocket_server.dart';

class StudioServer {
  final PlatformSDK sdk;
  final EventBus eventBus = EventBus();

  late final WorkspaceService workspaceService;
  late final SearchService searchService;
  late final AgentService agentService;
  late final MetricsService metricsService;
  late final ArchitectureService architectureService;
  late final InspectorService inspectorService;

  late final WorkspaceController workspaceController;
  late final SearchController searchController;
  late final AgentController agentController;
  late final MetricsController metricsController;
  late final ArchitectureController architectureController;
  late final InspectorController inspectorController;

  late final CodeIntelligenceService codeIntelService;
  late final CodeIntelligenceController codeIntelController;

  late final WebsocketServer websocketServer;

  HttpServer? _server;

  StudioServer(this.sdk) {
    workspaceService = WorkspaceService(sdk);
    searchService = SearchService(sdk);
    agentService = AgentService(sdk, eventBus);
    metricsService = MetricsService(sdk);
    architectureService = ArchitectureService(sdk);
    inspectorService = InspectorService(sdk);
    codeIntelService = CodeIntelligenceService(sdk);

    workspaceController = WorkspaceController(workspaceService);
    searchController = SearchController(searchService);
    agentController = AgentController(agentService);
    metricsController = MetricsController(metricsService);
    architectureController = ArchitectureController(architectureService);
    inspectorController = InspectorController(inspectorService);
    codeIntelController = CodeIntelligenceController(codeIntelService);

    websocketServer = WebsocketServer(eventBus);
    workspaceService.addWatcherListener((event) {
      websocketServer.broadcast(event);
      final path = event["path"];
      if (path is String && path.isNotEmpty) {
        codeIntelService.handleFileChanged(path);
      }
    });
  }

  Future<int> start({int preferredPort = 8080}) async {
    int port = preferredPort;
    while (true) {
      try {
        _server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
        break;
      } catch (e) {
        port++;
        if (port > preferredPort + 100) {
          rethrow;
        }
      }
    }

    _server!.listen(_handleRequest);
    await codeIntelService.initialize();
    return port;
  }

  void _handleRequest(HttpRequest request) async {
    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers
        .add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    request.response.headers.add('Access-Control-Allow-Headers',
        'Origin, X-Requested-With, Content-Type, Accept');

    if (request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.ok;
      await request.response.close();
      return;
    }

    final requestId = RequestLogger.logAndGenerateId(request);
    final path = request.uri.path;

    // WebSocket events route
    if (path == '/ws/events') {
      if (WebSocketTransformer.isUpgradeRequest(request)) {
        final socket = await WebSocketTransformer.upgrade(request);
        websocketServer.handleConnection(socket);
      } else {
        request.response.statusCode = HttpStatus.badRequest;
        await request.response.close();
      }
      return;
    }

    try {
      // 1. Legacy API routes mapping (Returns raw maps directly for backward compatibility)
      if (path == '/api/health') {
        final health = await sdk.health.checkHealth();
        final extended = {
          ...health,
          "Studio": "connected",
          "Plugin": "healthy",
        };
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(jsonEncode(extended));
      } else if (path == '/api/version') {
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({
            "platform": "1.0.0",
            "buildNumber": "1",
            "gitCommit": "19ee62b",
            "sdkVersion": "1.0.0",
            "schemaVersion": "v1"
          }));
      } else if (path == '/api/features') {
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({
            "KnowledgeSearch": sdk.featureFlags.isEnabled("KnowledgeSearch"),
            "DistributedExecution":
                sdk.featureFlags.isEnabled("DistributedExecution"),
            "MCP": sdk.featureFlags.isEnabled("MCP"),
            "StudioDiagnostics":
                sdk.featureFlags.isEnabled("StudioDiagnostics"),
            "ExperimentalAgents":
                sdk.featureFlags.isEnabled("ExperimentalAgents"),
          }));
      } else if (path == '/api/metrics') {
        final data = await metricsService.getMetricsSnapshot();
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({
            "workspaceFilesCount": data["workspace"]["filesCount"],
            "knowledgeChunksCount": data["knowledge"]["chunksCount"],
            "runtimeExecutedRequests": data["runtime"]["executedRequests"],
            "agentActiveSessionsCount": data["agents"]["activeSessionsCount"],
          }));
      } else if (path == '/api/workspace') {
        final data = await workspaceService.getWorkspaceTree();
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(jsonEncode(data));
      } else if (path == '/api/search') {
        final query = request.uri.queryParameters['q'] ?? '';
        final results =
            await searchService.searchCodebase(query: query, mode: "symbol");
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({"results": results}));
      } else if (path == '/api/run') {
        final record = await agentService.runWorkflow("Planner");
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(jsonEncode(record));
      }
      // 2. Versioned API Endpoints (api/v1/... returning ApiResponse DTO wrappers)
      else if (path == '/api/v1/health') {
        final health = await sdk.health.checkHealth();
        final extended = {
          ...health,
          "Studio": "connected",
          "Plugin": "healthy",
        };
        final response = ApiResponse(
          success: true,
          timestamp: DateTime.now().toIso8601String(),
          requestId: requestId,
          data: extended,
        );
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(response.toJsonString());
      } else if (path == '/api/v1/version') {
        final response = ApiResponse(
          success: true,
          timestamp: DateTime.now().toIso8601String(),
          requestId: requestId,
          data: {
            "platform": "1.0.0",
            "buildNumber": "1",
            "gitCommit": "19ee62b",
            "sdkVersion": "1.0.0",
            "schemaVersion": "v1"
          },
        );
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(response.toJsonString());
      } else if (path == '/api/v1/features') {
        final response = ApiResponse(
          success: true,
          timestamp: DateTime.now().toIso8601String(),
          requestId: requestId,
          data: {
            "KnowledgeSearch": sdk.featureFlags.isEnabled("KnowledgeSearch"),
            "DistributedExecution":
                sdk.featureFlags.isEnabled("DistributedExecution"),
            "MCP": sdk.featureFlags.isEnabled("MCP"),
            "StudioDiagnostics":
                sdk.featureFlags.isEnabled("StudioDiagnostics"),
            "ExperimentalAgents":
                sdk.featureFlags.isEnabled("ExperimentalAgents"),
          },
        );
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(response.toJsonString());
      } else if (path == '/api/v1/workspace') {
        await workspaceController.handleGetWorkspace(request, requestId);
      } else if (path == '/api/v1/workspace/file') {
        await workspaceController.handleGetFileContent(request, requestId);
      } else if (path == '/api/v1/workspace/stat') {
        await workspaceController.handleStat(request, requestId);
      } else if (path == '/api/v1/search') {
        await searchController.handleSearch(request, requestId);
      } else if (path == '/api/v1/metrics') {
        await metricsController.handleGetMetrics(request, requestId);
      } else if (path == '/api/v1/architecture') {
        await architectureController.handleGetTopology(request, requestId);
      } else if (path == '/api/v1/architecture/node') {
        await architectureController.handleGetNodeDetails(request, requestId);
      } else if (path == '/api/v1/inspector') {
        await inspectorController.handleInspect(request, requestId);
      } else if (path == '/api/v1/agent/run') {
        await agentController.handleRun(request, requestId);
      } else if (path == '/api/v1/agent/cancel') {
        await agentController.handleCancel(request, requestId);
      } else if (path == '/api/v1/agent/status') {
        await agentController.handleStatus(request, requestId);
      } else if (path == '/api/v1/agent/history') {
        await agentController.handleHistory(request, requestId);
      } else if (path == '/api/v1/agent/workflows') {
        await agentController.handleWorkflows(request, requestId);
      } else if (path == '/api/v1/code/outline') {
        await codeIntelController.handleGetOutline(request, requestId);
      } else if (path == '/api/v1/code/definition') {
        await codeIntelController.handleResolveDefinition(request, requestId);
      } else if (path == '/api/v1/code/references') {
        await codeIntelController.handleFindReferences(request, requestId);
      } else if (path == '/api/v1/code/workspaceSymbols') {
        await codeIntelController.handleSearchWorkspaceSymbols(
            request, requestId);
      } else if (path == '/api/v1/code/diagnostics') {
        await codeIntelController.handleGetIndexStatus(request, requestId);
      } else {
        final response = ApiResponse(
          success: false,
          timestamp: DateTime.now().toIso8601String(),
          requestId: requestId,
          data: const {},
          errors: ["Route not found: $path"],
        );
        request.response
          ..statusCode = HttpStatus.notFound
          ..headers.contentType = ContentType.json
          ..write(response.toJsonString());
      }
    } catch (e) {
      ErrorHandler.handle(request, e, requestId);
    } finally {
      await request.response.close();
    }
  }

  Future<void> stop() async {
    websocketServer.closeAll();
    await _server?.close(force: true);
  }
}
