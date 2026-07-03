import 'dart:convert';
import 'dart:io';
import '../../events/event_bus.dart';
import '../../events/runtime_event.dart';

class WebsocketServer {
  final EventBus eventBus;
  final List<WebSocket> _sockets = [];
  final List<Map<String, dynamic>> _replayBuffer = [];

  WebsocketServer(this.eventBus) {
    eventBus.stream.listen((event) {
      final category = _resolveCategory(event);
      final eventMap = {
        "version": "1.0.1",
        "category": category,
        "event": event.runtimeType.toString(),
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
  }

  void handleConnection(WebSocket ws) {
    _sockets.add(ws);

    // Replay buffer content to newly connected clients
    for (final item in _replayBuffer) {
      ws.add(jsonEncode(item));
    }

    ws.listen(
      (data) {},
      onDone: () => _sockets.remove(ws),
      onError: (err) => _sockets.remove(ws),
    );
  }

  String _resolveCategory(RuntimeEvent event) {
    final typeName = event.runtimeType.toString();
    if (typeName.contains('Workspace')) return "Workspace";
    if (typeName.contains('Knowledge') ||
        typeName.contains('Search') ||
        typeName.contains('Reindex')) return "Knowledge";
    if (typeName.contains('Task') || typeName.contains('Agent')) return "Agent";
    if (typeName.contains('Plugin')) return "Plugin";
    return "Runtime";
  }

  void closeAll() {
    for (final ws in _sockets) {
      ws.close();
    }
    _sockets.clear();
  }
}
