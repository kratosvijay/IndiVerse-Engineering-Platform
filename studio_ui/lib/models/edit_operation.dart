import '../core/services/workbench_providers.dart';
import 'editor_document.dart';

class OperationContext {
  final DateTime timestamp;
  final String source;

  const OperationContext({required this.timestamp, required this.source});
}

abstract class EditOperation {
  Future<OperationResult<void>> apply(
    EditorDocument document,
    OperationContext context,
  );
  Future<OperationResult<void>> revert(
    EditorDocument document,
    OperationContext context,
  );
}

class InsertTextOperation implements EditOperation {
  final int index;
  final String text;

  const InsertTextOperation({required this.index, required this.text});

  @override
  Future<OperationResult<void>> apply(
    EditorDocument document,
    OperationContext context,
  ) async {
    if (document.readOnly) {
      return const OperationResult.fail(
        WorkbenchError(
          code: "READ_ONLY",
          message: "Cannot edit a read-only document.",
        ),
      );
    }
    if (index < 0 || index > document.size) {
      return const OperationResult.fail(
        WorkbenchError(
          code: "OUT_OF_BOUNDS",
          message: "Insert index is out of bounds.",
        ),
      );
    }
    document.insertTextAtOffset(index, text);
    return const OperationResult.ok(null);
  }

  @override
  Future<OperationResult<void>> revert(
    EditorDocument document,
    OperationContext context,
  ) async {
    if (document.readOnly) {
      return const OperationResult.fail(
        WorkbenchError(
          code: "READ_ONLY",
          message: "Cannot edit a read-only document.",
        ),
      );
    }
    if (index < 0 || index + text.length > document.size) {
      return const OperationResult.fail(
        WorkbenchError(
          code: "OUT_OF_BOUNDS",
          message: "Revert delete index is out of bounds.",
        ),
      );
    }
    document.deleteTextAtOffset(index, text.length);
    return const OperationResult.ok(null);
  }
}

class DeleteTextOperation implements EditOperation {
  final int index;
  final String text;

  const DeleteTextOperation({required this.index, required this.text});

  @override
  Future<OperationResult<void>> apply(
    EditorDocument document,
    OperationContext context,
  ) async {
    if (document.readOnly) {
      return const OperationResult.fail(
        WorkbenchError(
          code: "READ_ONLY",
          message: "Cannot edit a read-only document.",
        ),
      );
    }
    if (index < 0 || index + text.length > document.size) {
      return const OperationResult.fail(
        WorkbenchError(
          code: "OUT_OF_BOUNDS",
          message: "Delete index is out of bounds.",
        ),
      );
    }
    document.deleteTextAtOffset(index, text.length);
    return const OperationResult.ok(null);
  }

  @override
  Future<OperationResult<void>> revert(
    EditorDocument document,
    OperationContext context,
  ) async {
    if (document.readOnly) {
      return const OperationResult.fail(
        WorkbenchError(
          code: "READ_ONLY",
          message: "Cannot edit a read-only document.",
        ),
      );
    }
    if (index < 0 || index > document.size) {
      return const OperationResult.fail(
        WorkbenchError(
          code: "OUT_OF_BOUNDS",
          message: "Revert insert index is out of bounds.",
        ),
      );
    }
    document.insertTextAtOffset(index, text);
    return const OperationResult.ok(null);
  }
}

class ReplaceTextOperation implements EditOperation {
  final int index;
  final String oldText;
  final String newText;

  const ReplaceTextOperation({
    required this.index,
    required this.oldText,
    required this.newText,
  });

  @override
  Future<OperationResult<void>> apply(
    EditorDocument document,
    OperationContext context,
  ) async {
    if (document.readOnly) {
      return const OperationResult.fail(
        WorkbenchError(
          code: "READ_ONLY",
          message: "Cannot edit a read-only document.",
        ),
      );
    }
    if (index < 0 || index + oldText.length > document.size) {
      return const OperationResult.fail(
        WorkbenchError(
          code: "OUT_OF_BOUNDS",
          message: "Replace index is out of bounds.",
        ),
      );
    }
    document.deleteTextAtOffset(index, oldText.length);
    document.insertTextAtOffset(index, newText);
    return const OperationResult.ok(null);
  }

  @override
  Future<OperationResult<void>> revert(
    EditorDocument document,
    OperationContext context,
  ) async {
    if (document.readOnly) {
      return const OperationResult.fail(
        WorkbenchError(
          code: "READ_ONLY",
          message: "Cannot edit a read-only document.",
        ),
      );
    }
    if (index < 0 || index + newText.length > document.size) {
      return const OperationResult.fail(
        WorkbenchError(
          code: "OUT_OF_BOUNDS",
          message: "Revert replace index is out of bounds.",
        ),
      );
    }
    document.deleteTextAtOffset(index, newText.length);
    document.insertTextAtOffset(index, oldText);
    return const OperationResult.ok(null);
  }
}
