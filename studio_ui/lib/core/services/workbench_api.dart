import 'dart:async';
import '../../models/ids.dart';
import '../../models/editor_document.dart';
import '../state/studio_state.dart';
import 'workbench_providers.dart';

abstract class WorkbenchApiV1 {
  NavigationApi get navigation;
  EditorApi get editor;
  SymbolApi get symbol;
  SearchApi get search;
  WorkspaceApi get workspace;
  NotificationApi get notification;
}

class WorkbenchApi implements WorkbenchApiV1 {
  final StudioState state;
  @override
  late final NavigationApi navigation;
  @override
  late final EditorApi editor;
  @override
  late final SymbolApi symbol;
  @override
  late final SearchApi search;
  @override
  late final WorkspaceApi workspace;
  @override
  late final NotificationApi notification;

  WorkbenchApi(this.state) {
    navigation = NavigationApi(this);
    editor = EditorApi(this);
    symbol = SymbolApi(this);
    search = SearchApi(this);
    workspace = WorkspaceApi(this);
    notification = NotificationApi(this);
  }
}

class NavigationApi {
  final WorkbenchApi _api;
  NavigationApi(this._api);

  void revealInExplorer(DocumentId id) {
    _api.state.revealInExplorer(id.value);
    _api.state.eventBus.publish("Navigation", "Revealed in explorer: ${id.value}");
  }

  void jumpToLine(DocumentId id, int line) {
    _api.state.openFile(id.value, line: line);
    _api.state.eventBus.publish("Navigation", "Jumped to line $line in document ${id.value}");
  }

  void selectSymbol(SymbolId id) {
    _api.state.selectInspector(id.value, "workspace");
    _api.state.eventBus.publish("Navigation", "Selected symbol: ${id.value}");
  }
}

class EditorApi {
  final WorkbenchApi _api;
  EditorApi(this._api);

  Future<OperationResult<EditorDocument>> openDocument(DocumentId id) async {
    try {
      await _api.state.openFile(id.value);
      final doc = _api.state.documentService.getDocument(id);
      if (doc != null) {
        _api.state.eventBus.publish("Editor", "Opened document: ${id.value}");
        return OperationResult.ok(doc);
      }
      return const OperationResult.fail(WorkbenchError(
        code: "FILE_NOT_FOUND",
        message: "Failed to open document: file not found.",
      ));
    } catch (e) {
      return OperationResult.fail(WorkbenchError(
        code: "LOAD_FAILED",
        message: e.toString(),
      ));
    }
  }

  void closeDocument(DocumentId id) {
    final idx = _api.state.editor.tabs.indexWhere((t) => t.document.path == id.value);
    if (idx != -1) {
      _api.state.editor.close(idx);
      _api.state.documentService.removeDocument(id);
      _api.state.eventBus.publish("Editor", "Closed document: ${id.value}");
    }
  }

  void activateDocument(DocumentId id) {
    final idx = _api.state.editor.tabs.indexWhere((t) => t.document.path == id.value);
    if (idx != -1) {
      _api.state.editor.activate(idx);
      _api.state.eventBus.publish("Editor", "Activated tab for document: ${id.value}");
    }
  }
}

class SymbolApi {
  final WorkbenchApi _api;
  SymbolApi(this._api);

  Future<OperationResult<List<Map<String, dynamic>>>> openOutline(DocumentId id) async {
    try {
      final res = await _api.state.fetchOutline(id);
      return OperationResult.ok(res);
    } catch (e) {
      return OperationResult.fail(WorkbenchError(
        code: "OUTLINE_FAILED",
        message: e.toString(),
      ));
    }
  }

  Future<OperationResult<Map<String, dynamic>>> resolveDefinition(SymbolId id, CancellationToken token) async {
    try {
      final res = await _api.state.fetchDefinition(id);
      if (token.isCancelled) {
        return const OperationResult.fail(WorkbenchError(code: "CANCELLED", message: "Operation cancelled"));
      }
      if (res != null) {
        return OperationResult.ok(res);
      }
      return const OperationResult.fail(WorkbenchError(
        code: "SYMBOL_NOT_FOUND",
        message: "Symbol declaration not found.",
      ));
    } catch (e) {
      return OperationResult.fail(WorkbenchError(
        code: "RESOLVE_FAILED",
        message: e.toString(),
      ));
    }
  }

  Future<OperationResult<List<Map<String, dynamic>>>> findReferences(SymbolId id, CancellationToken token) async {
    try {
      final res = await _api.state.fetchReferences(id);
      if (token.isCancelled) {
        return const OperationResult.fail(WorkbenchError(code: "CANCELLED", message: "Operation cancelled"));
      }
      return OperationResult.ok(res);
    } catch (e) {
      return OperationResult.fail(WorkbenchError(
        code: "REFERENCES_FAILED",
        message: e.toString(),
      ));
    }
  }
}

class SearchApi {
  final WorkbenchApi _api;
  SearchApi(this._api);

  void search(String query) {
    _api.state.executeSearch(query);
    _api.state.eventBus.publish("Search", "Completed search query: $query");
  }
}

class WorkspaceApi {
  final WorkbenchApi _api;
  WorkspaceApi(this._api);

  void refreshWorkspace() {
    _api.state.reloadWorkspace();
    _api.state.eventBus.publish("Workspace", "Refreshed workspace file index");
  }

  Future<OperationResult<Map<String, dynamic>>> getIndexStatus() async {
    try {
      final res = await _api.state.fetchIndexStatus();
      return OperationResult.ok(res);
    } catch (e) {
      return OperationResult.fail(WorkbenchError(
        code: "INDEX_STATUS_FAILED",
        message: e.toString(),
      ));
    }
  }
}

class NotificationApi {
  final WorkbenchApi _api;
  NotificationApi(this._api);

  void showToast(String message) {
    _api.state.eventBus.publish("Notification", "Toast: $message");
  }

  void showProgress(String task) {
    _api.state.eventBus.publish("Notification", "Progress started: $task");
  }

  void hideProgress() {
    _api.state.eventBus.publish("Notification", "Progress completed");
  }

  void showError(String err) {
    _api.state.eventBus.publish("Notification", "Error: $err");
  }

  void showWarning(String warn) {
    _api.state.eventBus.publish("Notification", "Warning: $warn");
  }

  void showInfo(String info) {
    _api.state.eventBus.publish("Notification", "Info: $info");
  }
}
