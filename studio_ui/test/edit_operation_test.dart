import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/models/editor_document.dart';
import 'package:studio_ui/models/edit_operation.dart';
import 'package:studio_ui/core/services/document_history_service.dart';

void main() {
  group('EditOperation Tests', () {
    late EditorDocument doc;
    late OperationContext ctx;

    setUp(() {
      doc = EditorDocument(
        id: 'test.dart',
        path: 'test.dart',
        name: 'test.dart',
        content: 'Hello World',
        language: 'dart',
        encoding: 'utf8',
        lastModified: '',
        readOnly: false,
      );
      ctx = OperationContext(timestamp: DateTime.now(), source: 'test');
    });

    test('InsertTextOperation apply and revert', () async {
      const op = InsertTextOperation(index: 5, text: ' Big');
      final resApply = await op.apply(doc, ctx);
      expect(resApply.success, true);
      expect(doc.content, 'Hello Big World');
      expect(doc.state, DocumentState.dirty);

      final resRevert = await op.revert(doc, ctx);
      expect(resRevert.success, true);
      expect(doc.content, 'Hello World');
    });

    test('DeleteTextOperation apply and revert', () async {
      const op = DeleteTextOperation(index: 6, text: 'World');
      final resApply = await op.apply(doc, ctx);
      expect(resApply.success, true);
      expect(doc.content, 'Hello ');

      final resRevert = await op.revert(doc, ctx);
      expect(resRevert.success, true);
      expect(doc.content, 'Hello World');
    });

    test('ReplaceTextOperation apply and revert', () async {
      const op = ReplaceTextOperation(
        index: 6,
        oldText: 'World',
        newText: 'IndiVerse',
      );
      final resApply = await op.apply(doc, ctx);
      expect(resApply.success, true);
      expect(doc.content, 'Hello IndiVerse');

      final resRevert = await op.revert(doc, ctx);
      expect(resRevert.success, true);
      expect(doc.content, 'Hello World');
    });
  });

  group('DocumentHistoryService Tests', () {
    late EditorDocument doc;
    late OperationContext ctx;
    late DocumentHistoryService historyService;

    setUp(() {
      doc = EditorDocument(
        id: 'test_hist.dart',
        path: 'test_hist.dart',
        name: 'test_hist.dart',
        content: 'Initial text',
        language: 'dart',
        encoding: 'utf8',
        lastModified: '',
        readOnly: false,
      );
      ctx = OperationContext(timestamp: DateTime.now(), source: 'test');
      historyService = DocumentHistoryService();
    });

    test('Undo and Redo stack traversal', () async {
      const op1 = InsertTextOperation(index: 12, text: ' edit1');
      await op1.apply(doc, ctx);
      historyService.recordOperation(doc.id, op1);

      const op2 = InsertTextOperation(index: 18, text: ' edit2');
      await op2.apply(doc, ctx);
      historyService.recordOperation(doc.id, op2);

      expect(doc.content, 'Initial text edit1 edit2');

      // First undo
      final undo1 = await historyService.undo(doc, ctx);
      expect(undo1.success, true);
      expect(doc.content, 'Initial text edit1');

      // Second undo
      final undo2 = await historyService.undo(doc, ctx);
      expect(undo2.success, true);
      expect(doc.content, 'Initial text');

      // Redo once
      final redo1 = await historyService.redo(doc, ctx);
      expect(redo1.success, true);
      expect(doc.content, 'Initial text edit1');

      // Redo twice
      final redo2 = await historyService.redo(doc, ctx);
      expect(redo2.success, true);
      expect(doc.content, 'Initial text edit1 edit2');
    });
  });
}
