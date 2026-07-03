import '../../events/runtime_event.dart';

class WorkspaceOpened extends RuntimeEvent {
  final String rootPath;

  WorkspaceOpened({
    required DateTime timestamp,
    required String eventId,
    required this.rootPath,
  }) : super(timestamp: timestamp, eventId: eventId);
}

class WorkspaceClosed extends RuntimeEvent {
  final String rootPath;

  WorkspaceClosed({
    required DateTime timestamp,
    required String eventId,
    required this.rootPath,
  }) : super(timestamp: timestamp, eventId: eventId);
}

class WorkspaceReady extends RuntimeEvent {
  final String rootPath;

  WorkspaceReady({
    required DateTime timestamp,
    required String eventId,
    required this.rootPath,
  }) : super(timestamp: timestamp, eventId: eventId);
}

class WorkspaceRefreshing extends RuntimeEvent {
  final String rootPath;

  WorkspaceRefreshing({
    required DateTime timestamp,
    required String eventId,
    required this.rootPath,
  }) : super(timestamp: timestamp, eventId: eventId);
}
