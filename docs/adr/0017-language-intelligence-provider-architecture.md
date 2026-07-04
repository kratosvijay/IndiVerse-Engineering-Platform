# ADR 0017 — Language Intelligence Provider Architecture

## Status
Approved

## Context
As IndiVerse Studio evolves into a professional development environment, it must provide "smart" editor features such as parameter details, documentation tooltips (Hover), error/warning reporting (Diagnostics), semantic colorization, and context-aware completion.

To keep these features decoupled from editor rendering (ADR 0016) and commands (ADR 0015), we need a standardized provider abstraction layer. This will allow us to easily swap out intelligence engines (e.g., local Regex/Tree-sitter parsers, remote LSP servers, or AI assistant agents) without touching UI widgets.

## Decision
We enforce a **Language Intelligence Provider Architecture** separating the registry from the coordinator service, with asynchronous, cancellable, and prioritized lifecycle-aware provider contracts.

### 1. Architectural Diagram

```
  [Editor Widget / Painter]
              │
              ▼
 [LanguageIntelligenceService] (Orchestration / Cache / Performance Metrics)
              │
              ├─── [BackgroundScheduler] (Debouncing & Concurrency Controls)
              │
              ▼
   [LanguageProviderRegistry] (Dynamic Priorities, Capabilities Index, Health)
              │
              ▼
   [Language Capabilities] (Hover, Completion, Diagnostics, etc.)
```

### 2. Core Context & Control Models

```dart
class CancellationToken {
  bool _isCancelled = false;
  bool get isCancelled => _isCancelled;

  void cancel() {
    _isCancelled = true;
  }
}

class LanguageContext {
  final EditorDocument document;
  final Position position;
  final SelectionRange? selection;
  final String workspace;
  final int workspaceRevision;
  final CancellationToken token;

  const LanguageContext({
    required this.document,
    required this.position,
    this.selection,
    required this.workspace,
    required this.workspaceRevision,
    required this.token,
  });
}

class LanguageRequest {
  final String id;
  final LanguageContext context;
  final Duration timeout;

  const LanguageRequest({
    required this.id,
    required this.context,
    required this.timeout,
  });
}

enum ProviderState {
  ready,
  initializing,
  unavailable,
  failed,
}

class ProviderMetrics {
  int requestCount = 0;
  int successCount = 0;
  int failedCount = 0;
  Duration totalLatency = Duration.zero;

  Duration get averageLatency => requestCount == 0 
      ? Duration.zero 
      : totalLatency ~/ requestCount;
}

abstract class LanguageProvider {
  String get id;
  String get language;
  int get version;
  int get priority; // Dynamic priority at runtime
  
  ProviderState get state;
  ProviderMetrics get metrics;

  // Lifecycle Support
  Future<void> initialize();
  Future<void> start();
  Future<void> stop();
  Future<void> dispose();
}
```

### 3. Provider Capabilities & Results

```dart
class ProviderCapabilities {
  final bool hover;
  final bool completion;
  final bool diagnostics;
  final bool semanticTokens;
  final bool rename;

  const ProviderCapabilities({
    this.hover = false,
    this.completion = false,
    this.diagnostics = false,
    this.semanticTokens = false,
    this.rename = false,
  });
}

class SemanticTokensResult {
  final bool isDelta;
  final List<int> data;
  final String? resultId;

  const SemanticTokensResult({
    this.isDelta = false,
    required this.data,
    this.resultId,
  });
}
```

### 4. Provider Interfaces

```dart
abstract class HoverProvider implements LanguageProvider {
  Future<OperationResult<Hover>> provideHover(LanguageRequest request);
}

abstract class SemanticTokensProvider implements LanguageProvider {
  Future<OperationResult<SemanticTokensResult>> provideSemanticTokens(LanguageRequest request);
}

abstract class DiagnosticsProvider implements LanguageProvider {
  Future<OperationResult<List<Diagnostic>>> provideDiagnostics(LanguageRequest request);
}

abstract class CompletionItemProvider implements LanguageProvider {
  Future<OperationResult<List<CompletionItem>>> provideCompletions(LanguageRequest request);
}

abstract class SignatureHelpProvider implements LanguageProvider {
  Future<OperationResult<SignatureHelp>> provideSignatureHelp(LanguageRequest request);
}

abstract class CodeActionProvider implements LanguageProvider {
  Future<OperationResult<List<CodeAction>>> provideCodeActions(LanguageRequest request);
}

// Future-Reserved Abstractions
abstract class RenameProvider implements LanguageProvider {
  Future<OperationResult<WorkspaceEdit>> provideRename(LanguageRequest request, String newName);
}

abstract class FormattingProvider implements LanguageProvider {
  Future<OperationResult<List<TextEdit>>> provideFormatting(LanguageRequest request);
}

abstract class DocumentSymbolsProvider implements LanguageProvider {
  Future<OperationResult<List<DocumentSymbol>>> provideDocumentSymbols(LanguageRequest request);
}

abstract class CallHierarchyProvider implements LanguageProvider {
  Future<OperationResult<List<CallHierarchyItem>>> provideCallHierarchy(LanguageRequest request);
}

abstract class TypeHierarchyProvider implements LanguageProvider {
  Future<OperationResult<List<TypeHierarchyItem>>> provideTypeHierarchy(LanguageRequest request);
}

abstract class CodeLensProvider implements LanguageProvider {
  Future<OperationResult<List<CodeLens>>> provideCodeLenses(LanguageRequest request);
}

abstract class InlayHintProvider implements LanguageProvider {
  Future<OperationResult<List<InlayHint>>> provideInlayHints(LanguageRequest request);
}
```

### 5. Execution Policies & Timeouts

| Capability | Concurrency | Cancellation | Timeout | Debounce | Cacheable |
|---|---|---|---|---|---|
| **Hover** | Serial | Cancel Previous | 500 ms | 150 ms | Yes (until edit/revision change) |
| **Completion** | Serial | Cancel Previous | 250 ms | 50 ms | No |
| **Diagnostics** | Parallel | Cancel Previous | 5 s | 300 ms | Yes (until edit/revision change) |
| **Semantic Tokens** | Parallel | Cancel Previous | 5 s | 300 ms | Yes (until edit/revision change) |
| **Signature Help** | Serial | Cancel Previous | 250 ms | 50 ms | No |
| **Code Actions** | Serial | N/A (On Demand) | 1 s | 0 ms | No |

## Consequences
- **Dynamic Extensibility**: Dynamically loaded plugins register providers on `LanguageProviderRegistry` which validates capability matches and manages priorities.
- **Diagnostics Isolation**: Heavy diagnostics run concurrently on background isolates or worker threads, ensuring the editing renderer remains responsive.
- **Failsafe Monitoring**: Crashed providers report `ProviderState.failed`, triggering automated restarts or graceful fallback procedures.
