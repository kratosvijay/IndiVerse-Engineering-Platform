import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/core/state/studio_state.dart';
import 'package:studio_ui/models/editor_document.dart';
import 'package:studio_ui/models/language_intelligence_models.dart';
import 'package:studio_ui/models/diagnostic_collection.dart';
import 'package:studio_ui/features/problems/widgets/problems_panel.dart';
import 'package:studio_ui/models/ids.dart';

void main() {
  group('DiagnosticCollection Tests', () {
    test('updates diagnostics correctly and filters out stale', () {
      final collection = DiagnosticCollection();
      final diag = const Diagnostic(
        id: 'test.dart-err',
        message: ' brace mismatch ',
        range: SelectionRange(
          start: Position(line: 2, column: 5),
          end: Position(line: 2, column: 6),
        ),
        severity: DiagnosticSeverity.error,
        code: 'ERR_BRACE',
        source: 'compiler',
      );

      collection.updateForFile(
        path: 'test.dart',
        providerId: 'provider-1',
        revision: 2,
        diagnostics: [diag],
      );

      expect(collection.getForFile('test.dart').length, 1);
      expect(collection.getAll().length, 1);

      // Clean stale revisions
      collection.cleanStaleRevisions('test.dart', 3);
      expect(collection.getForFile('test.dart').isEmpty, isTrue);
    });
  });

  group('ProblemsPanel Widget Tests', () {
    testWidgets('renders problems grouped by file with severity counts', (
      WidgetTester tester,
    ) async {
      final state = StudioState();
      state.connect(18080);

      final diag1 = const Diagnostic(
        id: 'test.dart-err',
        message: 'Syntax Error',
        range: SelectionRange(
          start: Position(line: 1, column: 1),
          end: Position(line: 1, column: 5),
        ),
        severity: DiagnosticSeverity.error,
        code: 'SYNTAX_ERR',
        source: 'compiler',
      );

      final diag2 = const Diagnostic(
        id: 'test.dart-warn',
        message: 'Deprecated API usage',
        range: SelectionRange(
          start: Position(line: 3, column: 2),
          end: Position(line: 3, column: 15),
        ),
        severity: DiagnosticSeverity.warning,
        code: 'DEP_WARN',
        source: 'linter',
        tags: [DiagnosticTag.deprecated],
      );

      state.diagnostics.updateForFile(
        path: 'lib/main.dart',
        providerId: 'default-diagnostics',
        revision: 1,
        diagnostics: [diag1, diag2],
      );

      // Mock open document
      final doc = EditorDocument(
        id: 'lib/main.dart',
        path: 'lib/main.dart',
        name: 'main.dart',
        content: 'void main() {\n  var x = 1;\n}',
        language: 'dart',
        encoding: 'utf8',
        lastModified: '',
        readOnly: false,
      );
      state.editor.open(doc);
      state.documentService.cacheDocument(DocumentId('lib/main.dart'), doc);

      bool panelClosed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Expanded(child: Container()),
                ProblemsPanel(
                  state: state,
                  onClose: () {
                    panelClosed = true;
                  },
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check header title and filter badges
      expect(find.text('PROBLEMS'), findsOneWidget);
      expect(find.text('Errors (1)'), findsOneWidget);
      expect(find.text('Warnings (1)'), findsOneWidget);
      expect(find.text('Info (0)'), findsOneWidget);

      // Check grouped file header
      expect(find.text('main.dart'), findsOneWidget);
      expect(find.text('lib/main.dart'), findsOneWidget);

      // Check diagnostics items details
      expect(find.textContaining('Syntax Error (SYNTAX_ERR)'), findsOneWidget);
      expect(
        find.textContaining('Deprecated API usage (DEP_WARN)'),
        findsOneWidget,
      );

      // Click on Errors (1) filter badge to hide errors
      await tester.tap(find.text('Errors (1)'));
      await tester.pumpAndSettle();

      // Check that Errors count became 0 in the filtered results
      expect(find.textContaining('Syntax Error (SYNTAX_ERR)'), findsNothing);
      expect(
        find.textContaining('Deprecated API usage (DEP_WARN)'),
        findsOneWidget,
      );

      // Tap on close button
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(panelClosed, isTrue);
    });
  });
}
