import 'dart:async';

class WorkbenchEvent {
  final String id;
  final int sequence;
  final DateTime timestamp;
  final String category; // Workspace, Editor, Search, Agent, Notification, Git, Plugin
  final dynamic payload;

  const WorkbenchEvent({
    required this.id,
    required this.sequence,
    required this.timestamp,
    required this.category,
    required this.payload,
  });
}

class WorkbenchEventBus {
  final StreamController<WorkbenchEvent> _controller = StreamController<WorkbenchEvent>.broadcast();

  Stream<WorkbenchEvent> get stream => _controller.stream;

  Stream<WorkbenchEvent> on(String category) {
    return _controller.stream.where((event) => event.category.toLowerCase() == category.toLowerCase());
  }

  void publish(String category, dynamic payload) {
    final event = WorkbenchEvent(
      id: "evt-${DateTime.now().microsecondsSinceEpoch}",
      sequence: DateTime.now().millisecondsSinceEpoch,
      timestamp: DateTime.now(),
      category: category,
      payload: payload,
    );
    _controller.add(event);
  }

  void dispose() {
    _controller.close();
  }
}
