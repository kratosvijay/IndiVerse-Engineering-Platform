import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/core/state/studio_state.dart';
import 'package:studio_ui/models/editor_document.dart';
import 'package:studio_ui/models/language_intelligence_models.dart';
import 'package:studio_ui/core/services/language_intelligence_providers.dart';
import 'package:studio_ui/core/services/workbench_providers.dart';
import 'package:studio_ui/core/services/code_action_cache.dart';
import 'package:studio_ui/features/editor/widgets/code_action_lightbulb.dart';
import 'package:studio_ui/features/editor/widgets/code_action_overlay_widget.dart';
import 'package:studio_ui/features/editor/controllers/code_action_controller.dart';
import 'package:studio_ui/models/ids.dart';

class TestCodeActionProvider implements CodeActionProvider {
  @override
  final String id = 'test-codeactions';
  @override
  final String language = 'dart';
  @override
  final int version = 1;
  @override
  final int priority = 10;
  @override
  ProviderState state = ProviderState.ready;
  @override
  final ProviderMetrics metrics = ProviderMetrics();

  @override
  Future<void> initialize() async {}
  @override
  Future<void> start() async {}
  @override
  Future<void> stop() async {}
  @override
  Future<void> dispose() async {}

  @override
  Future<OperationResult<List<CodeAction>>> provideCodeActions(
    ProviderExecutionContext context,
  ) async {
    return const OperationResult.ok([
      CodeAction(
        id: 'fix-unused-variable',
        title: 'Remove variable',
        kind: CodeActionKind.quickFix,
        isPreferred: true,
        edit: WorkspaceEdit(
          changes: {
            'lib/main.dart': [
              TextEdit(
                range: SelectionRange(
                  start: Position(line: 2, column: 3),
                  end: Position(line: 2, column: 14),
                ),
                newText: '',
              ),
            ],
          },
        ),
      ),
      CodeAction(
        id: 'organize-imports',
        title: 'Organize Imports',
        kind: CodeActionKind.sourceOrganizeImports,
      ),
    ]);
  }
}

void main() {
  group('Code Actions Cache, Controller and Widget Tests', () {
    test('CodeActionCache put, get, and invalidatePath', () {
      final cache = CodeActionCache();
      const action = CodeAction(
        id: 'test-action',
        title: 'Fix quotes',
        kind: CodeActionKind.quickFix,
      );

      cache.put(
        'ws1',
        'lib/main.dart',
        1,
        const Position(line: 2, column: 5),
        ['diag1'],
        [action],
      );

      final cached = cache.get(
        'ws1',
        'lib/main.dart',
        1,
        const Position(line: 2, column: 5),
        ['diag1'],
      );
      expect(cached, isNotNull);
      expect(cached!.first.title, equals('Fix quotes'));

      cache.invalidatePath('lib/main.dart');
      expect(
        cache.get(
          'ws1',
          'lib/main.dart',
          1,
          const Position(line: 2, column: 5),
          ['diag1'],
        ),
        isNull,
      );
    });

    testWidgets('CodeActionLightbulb renders and clicks to show overlay', (
      WidgetTester tester,
    ) async {
      final state = StudioState();
      state.connect(18080);

      await state.languageRegistry.registerCodeActionProvider(
        'dart',
        TestCodeActionProvider(),
      );

      final doc = EditorDocument(
        id: 'lib/main.dart',
        path: 'lib/main.dart',
        name: 'main.dart',
        content: 'void main() {\n  var x = 42;\n}',
        language: 'dart',
        encoding: 'utf8',
        lastModified: '',
        readOnly: false,
      );
      state.editor.open(doc);
      state.documentService.cacheDocument(DocumentId('lib/main.dart'), doc);

      state.diagnostics.updateForFile(
        path: 'lib/main.dart',
        providerId: 'test-provider',
        revision: 1,
        diagnostics: [
          const Diagnostic(
            id: 'diag-unused-x',
            range: SelectionRange(
              start: Position(line: 2, column: 3),
              end: Position(line: 2, column: 14),
            ),
            severity: DiagnosticSeverity.warning,
            code: 'unused_variable',
            source: 'test-source',
            message: "The variable 'x' is not used.",
          ),
        ],
      );

      doc.updateCursor(const Position(line: 2, column: 5));

      state.codeActionController.triggerCodeActions(isManual: false);

      await tester.pump(const Duration(milliseconds: 100));

      final session = state.codeActionController.activeSession;
      expect(session, isNotNull);
      expect(session!.actions.length, equals(2));
      expect(session.isVisible, isFalse);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                CodeActionLightbulb(
                  session: session,
                  controller: state.codeActionController,
                  globalX: 10.0,
                  globalY: 20.0,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.lightbulb), findsOneWidget);

      await tester.tap(find.byIcon(Icons.lightbulb));
      await tester.pump();
      expect(session.isVisible, isTrue);
    });

    testWidgets('CodeActionOverlayWidget renders and lists available actions', (
      WidgetTester tester,
    ) async {
      final state = StudioState();
      final session = CodeActionSession(
        requestId: 'session-123',
        revision: 1,
        position: const Position(line: 2, column: 5),
        selection: const SelectionRange(
          start: Position(line: 2, column: 5),
          end: Position(line: 2, column: 5),
        ),
        actions: const [
          CodeAction(
            id: 'fix-unused-variable',
            title: 'Remove variable',
            kind: CodeActionKind.quickFix,
            isPreferred: true,
          ),
          CodeAction(
            id: 'organize-imports',
            title: 'Organize Imports',
            kind: CodeActionKind.sourceOrganizeImports,
          ),
        ],
        isVisible: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                CodeActionOverlayWidget(
                  session: session,
                  controller: state.codeActionController,
                  globalX: 50.0,
                  globalY: 100.0,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Remove variable'), findsOneWidget);
      expect(find.text('Organize Imports'), findsOneWidget);
      expect(find.text('Quick Fixes & Refactoring'), findsOneWidget);
    });
  });
}
