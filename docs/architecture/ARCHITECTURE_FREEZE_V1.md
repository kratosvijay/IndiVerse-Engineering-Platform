# Architecture Freeze v1.0 - IndiVerse Studio Workbench

This document freezes the workbench architecture of **IndiVerse Studio** at version `1.0.0` as of Sprint 17. All future features must conform to this design.

---

## 1. Layer Diagram
```
                     Presentation (UI Widgets)
                                │
                                ▼
               [WorkbenchApi] ➔ [WorkbenchApiV1]
                                │
     ┌──────────────┬───────────┼────────────┬─────────────┐
     ▼              ▼           ▼            ▼             ▼
NavigationApi   EditorApi   SymbolApi   WorkspaceApi   NotificationApi
                    │
                    ▼
            [DocumentService]  ◄───  [WorkbenchEventBus]
                    │
                    ▼
          Platform SDK Service Layer
                    │
                    ▼
              REST / WebSockets
                    │
                    ▼
         Platform SDK Backend Core
```

---

## 2. Service Lifecycle Contracts
All workbench services implement the common interface:
```dart
abstract class LifecycleService {
  Future<void> initialize();
  Future<void> start();
  Future<void> stop();
  Future<void> dispose();
}
```

---

## 3. Communication & Governance Contracts

### WorkbenchEventBus Payload
```dart
class WorkbenchEvent {
  final String id;
  final int sequence;
  final DateTime timestamp;
  final String category; // Workspace, Editor, Search, Agent, Notification, Git, Plugin
  final dynamic payload;
}
```

### OperationResult Envelope
```dart
class OperationResult<T> {
  final bool success;
  final T? data;
  final WorkbenchError? error;
}

class WorkbenchError {
  final String code; // FILE_NOT_FOUND, DOCUMENT_CLOSED, SYMBOL_NOT_FOUND, etc.
  final String message;
  final String? details;
}
```

### Command Object Structure
```dart
class Command {
  final CommandId id;
  final String title;
  final String category;
  final Shortcut? shortcut;
  final Future<void> Function(CommandContext context) handler;
}
```

---

## 4. Extension Provider Interfaces
```dart
abstract class DocumentProvider {}
abstract class CodeIntelligenceProvider {}
abstract class WorkspaceProvider {}
abstract class NotificationProvider {}
abstract class SearchProvider {}
abstract class EditorProvider {}
abstract class GitProvider {}
abstract class AgentProvider {}
```

---

## 5. Versioning Policy
- **Workbench API Versioning**: Access points are versioned (`WorkbenchApiV1`). Backward compatibility is maintained; deprecations persist for at least one minor version before removal in a major version.
- **Capabilities Versioning**: Plugins declare versions for requested capabilities (`SearchProvider: 1`) to isolate interface changes.
- **REST Endpoints**: Keep versioned under `/api/v1/code/*` to ease future integrations.
