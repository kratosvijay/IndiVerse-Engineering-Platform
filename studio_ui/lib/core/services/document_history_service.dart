import 'dart:async';
import '../../models/edit_operation.dart';
import '../../models/editor_document.dart';
import 'workbench_providers.dart';

class DocumentHistory {
  final List<EditOperation> undoStack = [];
  final List<EditOperation> redoStack = [];
}

class DocumentHistoryService {
  final Map<String, DocumentHistory> _histories = {};

  DocumentHistory _getOrCreateHistory(String docId) {
    return _histories.putIfAbsent(docId, () => DocumentHistory());
  }

  void recordOperation(String docId, EditOperation op) {
    final history = _getOrCreateHistory(docId);
    history.undoStack.add(op);
    history.redoStack.clear(); // Clear redo stack on new operation
  }

  Future<OperationResult<void>> undo(
    EditorDocument doc,
    OperationContext context,
  ) async {
    final history = _getOrCreateHistory(doc.id);
    if (history.undoStack.isEmpty) {
      return const OperationResult.fail(
        WorkbenchError(
          code: "NO_UNDO_HISTORY",
          message: "No operations to undo.",
        ),
      );
    }
    final op = history.undoStack.removeLast();
    final res = await op.revert(doc, context);
    if (res.success) {
      history.redoStack.add(op);
    } else {
      history.undoStack.add(op); // Put it back if failed
    }
    return res;
  }

  Future<OperationResult<void>> redo(
    EditorDocument doc,
    OperationContext context,
  ) async {
    final history = _getOrCreateHistory(doc.id);
    if (history.redoStack.isEmpty) {
      return const OperationResult.fail(
        WorkbenchError(
          code: "NO_REDO_HISTORY",
          message: "No operations to redo.",
        ),
      );
    }
    final op = history.redoStack.removeLast();
    final res = await op.apply(doc, context);
    if (res.success) {
      history.undoStack.add(op);
    } else {
      history.redoStack.add(op); // Put it back if failed
    }
    return res;
  }

  void clearHistory(String docId) {
    _histories.remove(docId);
  }
}
