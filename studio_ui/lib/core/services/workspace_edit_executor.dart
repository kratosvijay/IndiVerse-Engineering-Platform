import '../state/studio_state.dart';
import '../../models/language_intelligence_models.dart';
import '../../models/ids.dart';
import '../../models/editor_document.dart';
import '../../models/edit_operation.dart';
import 'workbench_providers.dart';

class WorkspaceEditExecutor {
  final StudioState state;

  WorkspaceEditExecutor({required this.state});

  Future<OperationResult<void>> execute(
    WorkspaceEdit edit, {
    int? expectedRevision,
  }) async {
    // 1. Validation phase
    for (final entry in edit.changes.entries) {
      final path = entry.key;
      final docId = DocumentId(path);
      final doc = state.documentService.getDocument(docId);

      if (doc == null) {
        return OperationResult.fail(
          WorkbenchError(
            code: 'FILE_NOT_FOUND',
            message: 'File not found in workspace: $path',
          ),
        );
      }

      if (expectedRevision != null &&
          doc.version.localRevision != expectedRevision) {
        return OperationResult.fail(
          WorkbenchError(
            code: 'REVISION_MISMATCH',
            message:
                'Document revision mismatch. Expected $expectedRevision but got ${doc.version.localRevision}.',
          ),
        );
      }

      // Check range validity
      for (final textEdit in entry.value) {
        try {
          final startOffset = doc.positionToOffset(textEdit.range.start);
          final endOffset = doc.positionToOffset(textEdit.range.end);
          if (startOffset < 0 ||
              endOffset > doc.content.length ||
              startOffset > endOffset) {
            return OperationResult.fail(
              const WorkbenchError(
                code: 'INVALID_RANGE',
                message: 'TextEdit range is invalid or out of bounds.',
              ),
            );
          }
        } catch (e) {
          return OperationResult.fail(
            WorkbenchError(
              code: 'INVALID_RANGE',
              message: 'Failed to convert range to offset: $e',
            ),
          );
        }
      }
    }

    // 2. Execution phase
    final context = OperationContext(
      timestamp: DateTime.now(),
      source: "codeAction",
    );

    for (final entry in edit.changes.entries) {
      final path = entry.key;
      final docId = DocumentId(path);
      final doc = state.documentService.getDocument(docId)!;

      // Sort edits in descending order to avoid offset shifting issues
      final edits = List<TextEdit>.from(entry.value);
      edits.sort((a, b) => _comparePosition(b.range.start, a.range.start));

      for (final textEdit in edits) {
        final startOffset = doc.positionToOffset(textEdit.range.start);
        final endOffset = doc.positionToOffset(textEdit.range.end);
        final oldText = doc.content.substring(startOffset, endOffset);

        final op = ReplaceTextOperation(
          index: startOffset,
          oldText: oldText,
          newText: textEdit.newText,
        );

        final res = await op.apply(doc, context);
        if (res.success) {
          state.history.recordOperation(doc.id, op);
        } else {
          return OperationResult.fail(
            WorkbenchError(
              code: 'APPLY_FAILED',
              message: 'Failed to apply edit operation.',
            ),
          );
        }
      }
    }

    state.refreshUI();
    return const OperationResult.ok(null);
  }

  int _comparePosition(Position p1, Position p2) {
    if (p1.line != p2.line) return p1.line.compareTo(p2.line);
    return p1.column.compareTo(p2.column);
  }
}
