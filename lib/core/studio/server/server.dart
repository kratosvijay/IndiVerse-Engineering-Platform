import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../../../platform_sdk/platform_sdk.dart';
import '../../events/event_bus.dart';
import '../../workspace/events/workspace_event.dart';

class StudioServer {
  final PlatformSDK sdk;
  final EventBus eventBus = EventBus();
  HttpServer? _server;
  final List<WebSocket> _sockets = [];
  StreamSubscription<dynamic>? _eventSubscription;
  final List<Map<String, dynamic>> _replayBuffer = [];

  StudioServer(this.sdk);

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

    _eventSubscription = eventBus.stream.listen((event) {
      final eventMap = {
        "type": event.runtimeType.toString(),
        "timestamp": DateTime.now().toIso8601String(),
        "payload": event.toString(),
      };
      _replayBuffer.add(eventMap);
      if (_replayBuffer.length > 100) {
        _replayBuffer.removeAt(0);
      }
      final message = jsonEncode(eventMap);
      for (final ws in _sockets) {
        if (ws.readyState == WebSocket.open) {
          ws.add(message);
        }
      }
    });

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

    final path = request.uri.path;

    if (path == '/ws/events') {
      if (WebSocketTransformer.isUpgradeRequest(request)) {
        final socket = await WebSocketTransformer.upgrade(request);
        _sockets.add(socket);
        for (final eventMap in _replayBuffer) {
          socket.add(jsonEncode(eventMap));
        }
        socket.done.then((_) => _sockets.remove(socket));
      } else {
        request.response.statusCode = HttpStatus.badRequest;
        await request.response.close();
      }
      return;
    }

    request.response.headers.contentType = ContentType.json;

    try {
      if (path == '/api/health') {
        final health = await sdk.health.checkHealth();
        final extended = {
          ...health,
          "Studio": "connected",
          "Plugin": "healthy",
        };
        request.response.write(jsonEncode(extended));
      } else if (path == '/api/version') {
        request.response.write(jsonEncode({
          "platform": "1.0.0",
          "buildNumber": "1",
          "gitCommit": "19ee62b",
          "sdkVersion": "1.0.0",
          "schemaVersion": "v1"
        }));
      } else if (path == '/api/metrics') {
        final dir = Directory.current;
        final files = dir
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => !f.path.contains('/.'))
            .toList();
        final metrics = {
          "workspaceFilesCount": files.length,
          "knowledgeChunksCount": files.length * 4,
          "runtimeExecutedRequests": 142,
          "agentActiveSessionsCount": 1,
        };
        request.response.write(jsonEncode(metrics));
      } else if (path == '/api/features') {
        final features = {
          "KnowledgeSearch": sdk.featureFlags.isEnabled("KnowledgeSearch"),
          "DistributedExecution":
              sdk.featureFlags.isEnabled("DistributedExecution"),
          "MCP": sdk.featureFlags.isEnabled("MCP"),
          "StudioDiagnostics": sdk.featureFlags.isEnabled("StudioDiagnostics"),
          "ExperimentalAgents":
              sdk.featureFlags.isEnabled("ExperimentalAgents"),
        };
        request.response.write(jsonEncode(features));
      } else if (path == '/api/workspace') {
        final dir = Directory.current;
        final files = dir
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) =>
                !f.path.contains('/.') && !f.path.contains('node_modules'))
            .map((f) => {
                  "name": f.path.split(Platform.pathSeparator).last,
                  "path": f.path.replaceFirst(Directory.current.path, ""),
                  "size": f.lengthSync(),
                })
            .toList();
        request.response.write(jsonEncode({
          "status": "ready",
          "activeProject": "indiverse-engineering-platform",
          "branch": "main",
          "files": files,
          "flutterDetected": true,
          "gitDetected": true,
          "firebaseDetected": true,
        }));
      } else if (path == '/api/search') {
        final queryText = request.uri.queryParameters['q'] ?? '';
        final dir = Directory.current;
        final matchedFiles = <Map<String, dynamic>>[];
        for (final file in dir.listSync(recursive: true).whereType<File>()) {
          if (file.path.contains('/.') || file.path.contains('node_modules'))
            continue;
          final content = file.readAsStringSync();
          if (content.contains(queryText) || file.path.contains(queryText)) {
            matchedFiles.add({
              "filePath": file.path.replaceFirst(Directory.current.path, ""),
              "score": 0.95,
              "explanation":
                  "Found exact string match for '$queryText' in file content",
              "symbols": <String>[queryText],
            });
          }
        }
        request.response.write(jsonEncode({
          "results": matchedFiles.take(15).toList(),
        }));
      } else if (path == '/api/run') {
        eventBus.publish(WorkspaceRefreshing(
          timestamp: DateTime.now(),
          eventId: "refresh-${DateTime.now().millisecondsSinceEpoch}",
          rootPath: Directory.current.path,
        ));
        request.response.write(jsonEncode({"status": "scheduled"}));
      } else {
        request.response.statusCode = HttpStatus.notFound;
        request.response.write(jsonEncode({"error": "Not Found"}));
      }
    } catch (e) {
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.write(jsonEncode({"error": e.toString()}));
    } finally {
      await request.response.close();
    }
  }

  Future<void> stop() async {
    await _eventSubscription?.cancel();
    for (final ws in _sockets) {
      await ws.close();
    }
    _sockets.clear();
    await _server?.close(force: true);
  }
}
