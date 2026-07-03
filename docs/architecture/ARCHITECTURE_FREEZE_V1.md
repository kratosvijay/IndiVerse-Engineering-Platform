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

## 3. Communication Contracts

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
- **Minor Changes (v1.x.y)**: Feature additions conforming strictly to these layers.
- **Major Changes (v2.0.0)**: Reserved for deep architectural evolutions.
- **REST Endpoints**: Keep versioned under `/api/v1/code/*` to ease future integrations.
