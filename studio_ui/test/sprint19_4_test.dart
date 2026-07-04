import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/models/editor_document.dart';
import 'package:studio_ui/models/edit_operation.dart';
import 'package:studio_ui/core/services/recovery_service.dart';

void main() {
  group('Workspace Locking Tests', () {
    test('Edit operations blocked when doc is locked', () async {
      final doc = EditorDocument(
        id: 'test.dart',
        path: 'test.dart',
        name: 'test.dart',
        content: 'Hello World',
        language: 'dart',
        encoding: 'utf8',
        lastModified: '',
        readOnly: false,
      );

      // Lock document
      doc.lockReason = DocumentLockReason.saving;
      expect(doc.lockReason, DocumentLockReason.saving);

      const op = InsertTextOperation(index: 5, text: ' Big');
      final ctx = OperationContext(timestamp: DateTime.now(), source: 'test');
      final res = await op.apply(doc, ctx);

      expect(res.success, false);
      expect(res.error?.code, 'LOCKED');
      expect(doc.content, 'Hello World'); // Content not changed
    });
  });

  group('Recovery Service Schema & Atomic Write Tests', () {
    late Directory testDir;
    late RecoveryService recoveryService;

    setUp(() {
      testDir = Directory.systemTemp.createTempSync('recovery_test');
      recoveryService = RecoveryService(workspaceRoot: testDir.path);
    });

    tearDown(() {
      testDir.deleteSync(recursive: true);
    });

    test('Save and restore full recovery session', () async {
      final session = RecoverySession(
        workspace: testDir.path,
        savedAt: DateTime.now(),
        documents: [
          RecoveredDocument(
            path: 'main.dart',
            cursor: const Position(line: 15, column: 8),
            scrollOffset: 120.0,
            folds: [RecoveredFold(startLine: 5, endLine: 8, collapsed: true)],
            revision: 3,
            isDirty: true,
            buffer: 'void main() {}',
          ),
        ],
        activeTabIndex: 0,
      );

      await recoveryService.save(session);

      // Check recovery.json exists, recovery.json.tmp does not
      final recoveryFile = File('${testDir.path}/.agents/recovery.json');
      final tmpFile = File('${testDir.path}/.agents/recovery.json.tmp');
      expect(recoveryFile.existsSync(), true);
      expect(tmpFile.existsSync(), false);

      final restored = await recoveryService.restore();
      expect(restored, isNotNull);
      expect(restored!.documents.length, 1);
      expect(restored.documents[0].path, 'main.dart');
      expect(restored.documents[0].cursor.line, 15);
      expect(restored.documents[0].folds[0].startLine, 5);
      expect(restored.documents[0].buffer, 'void main() {}');
    });

    test('Ignore corrupted recovery json', () async {
      final recoveryFile = File('${testDir.path}/.agents/recovery.json');
      recoveryFile.createSync(recursive: true);
      recoveryFile.writeAsStringSync('{invalid json}');

      final restored = await recoveryService.restore();
      expect(restored, isNull);
    });
  });
}
