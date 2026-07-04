import 'dart:async';
import '../../models/ids.dart';
import '../../models/editor_document.dart';

class CancellationToken {
  bool _cancelled = false;
  bool get isCancelled => _cancelled;
  void cancel() => _cancelled = true;
}

class OperationResult<T> {
  final bool success;
  final T? data;
  final WorkbenchError? error;

  const OperationResult.ok(this.data) : success = true, error = null;
  const OperationResult.fail(this.error) : success = false, data = null;
}

class WorkbenchError {
  final String code;
  final String message;
  final String? details;

  const WorkbenchError({
    required this.code,
    required this.message,
    this.details,
  });
}

abstract class WorkspaceProvider {
  Future<OperationResult<Map<String, dynamic>>> getIndexStatus();
  Future<OperationResult<List<dynamic>>> fetchDirectory(String path);
}

abstract class CodeIntelligenceProvider {
  Future<OperationResult<List<Map<String, dynamic>>>> getOutline(
    DocumentId id,
    CancellationToken token,
  );
  Future<OperationResult<Map<String, dynamic>>> resolveDefinition(
    SymbolId id,
    CancellationToken token,
  );
  Future<OperationResult<List<Map<String, dynamic>>>> findReferences(
    SymbolId id,
    CancellationToken token,
  );
}

abstract class NotificationProvider {
  void showToast(String message);
  void showProgress(String task);
  void hideProgress();
  void showError(String err);
  void showWarning(String warn);
  void showInfo(String info);
}

abstract class SearchProvider {
  Future<OperationResult<List<dynamic>>> search(
    String query,
    CancellationToken token,
  );
}

abstract class EditorProvider {
  Future<OperationResult<EditorDocument>> loadDocument(DocumentId id);
}
