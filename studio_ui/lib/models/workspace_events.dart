abstract class WorkspaceEvent {
  final String path;
  final DateTime timestamp;
  WorkspaceEvent(this.path, this.timestamp);
}

class WorkspaceCreatedEvent extends WorkspaceEvent {
  WorkspaceCreatedEvent(super.path, super.timestamp);
}

class WorkspaceModifiedEvent extends WorkspaceEvent {
  WorkspaceModifiedEvent(super.path, super.timestamp);
}

class WorkspaceDeletedEvent extends WorkspaceEvent {
  WorkspaceDeletedEvent(super.path, super.timestamp);
}

class WorkspaceRenamedEvent extends WorkspaceEvent {
  final String oldPath;
  WorkspaceRenamedEvent(this.oldPath, String newPath, DateTime ts)
    : super(newPath, ts);
}

abstract class DocumentEvent {
  final String path;
  DocumentEvent(this.path);
}

class DocumentConflictEvent extends DocumentEvent {
  final String diskModifiedAt;
  final int localRevision;
  DocumentConflictEvent(super.path, this.diskModifiedAt, this.localRevision);
}

class DocumentReloadedEvent extends DocumentEvent {
  DocumentReloadedEvent(super.path);
}

enum WorkspaceWatcherState { connected, disconnected, reconnecting }
