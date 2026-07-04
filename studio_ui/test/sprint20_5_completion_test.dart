import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/core/state/studio_state.dart';
import 'package:studio_ui/models/editor_document.dart';
import 'package:studio_ui/models/language_intelligence_models.dart';
import 'package:studio_ui/core/services/language_intelligence_providers.dart';
import 'package:studio_ui/core/services/workbench_providers.dart';
import 'package:studio_ui/core/services/completion_cache.dart';
import 'package:studio_ui/core/services/completion_ranker.dart';
import 'package:studio_ui/features/editor/widgets/completion_overlay_widget.dart';
import 'package:studio_ui/models/ids.dart';

class TestCompletionItemProvider implements CompletionItemProvider {
  @override
  final String id = 'test-completion';
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
  Future<OperationResult<List<CompletionItem>>> provideCompletions(
    ProviderExecutionContext context,
  ) async {
    return const OperationResult.ok([
      CompletionItem(
        label: 'print',
        kind: CompletionItemKind.function,
        detail: 'print message',
        documentation: 'Prints string representation of object to console.',
        insertText: 'print()',
      ),
      CompletionItem(
        label: 'printError',
        kind: CompletionItemKind.function,
        detail: 'print error message',
        insertText: 'printError()',
      ),
      CompletionItem(
        label: 'Scaffold',
        kind: CompletionItemKind.classType,
        detail: 'material library widget',
        insertText: 'Scaffold',
      ),
    ]);
  }
}

void main() {
  group('Completion Cache and Ranker Tests', () {
    test('CompletionCache stores and invalidates correctly', () async {
      final cache = CompletionCache(timeout: const Duration(seconds: 1));
      final items = [
        const CompletionItem(
          label: 'print',
          kind: CompletionItemKind.function,
          insertText: 'print()',
        ),
      ];

      cache.put('dart', 'v1', 'lib/main.dart', 1, 'pr', items);

      final cached = cache.get('dart', 'v1', 'lib/main.dart', 1, 'pr');
      expect(cached, isNotNull);
      expect(cached!.first.label, 'print');

      // Invalidate revision test
      cache.invalidateRevision('lib/main.dart', 2);
      final cachedStale = cache.get('dart', 'v1', 'lib/main.dart', 1, 'pr');
      expect(cachedStale, isNull);
    });

    test('CompletionRanker orders suggestions by prefix/fuzzy score', () {
      final items = [
        const CompletionItem(
          label: 'printError',
          kind: CompletionItemKind.function,
          insertText: 'printError()',
        ),
        const CompletionItem(
          label: 'print',
          kind: CompletionItemKind.function,
          insertText: 'print()',
        ),
        const CompletionItem(
          label: 'Scaffold',
          kind: CompletionItemKind.classType,
          insertText: 'Scaffold',
        ),
      ];

      // prefix exact match prints should be sorted first
      final results = CompletionRanker.rank(items, 'print');
      expect(results.first.label, 'print');
      expect(results[1].label, 'printError');
      expect(results.length, 2); // Scaffold does not contain prefix 'print'
    });
  });

  group('Autocomplete Session and Overlay Widget Tests', () {
    testWidgets('CompletionOverlayWidget renders suggestion details', (
      WidgetTester tester,
    ) async {
      final state = StudioState();
      state.connect(18080);

      await state.languageRegistry.registerCompletionProvider(
        'dart',
        TestCompletionItemProvider(),
      );

      final doc = EditorDocument(
        id: 'lib/main.dart',
        path: 'lib/main.dart',
        name: 'main.dart',
        content: 'void main() {\n  pr\n}',
        language: 'dart',
        encoding: 'utf8',
        lastModified: '',
        readOnly: false,
      );
      state.editor.open(doc);
      state.documentService.cacheDocument(DocumentId('lib/main.dart'), doc);
      doc.updateCursor(const Position(line: 2, column: 5));

      state.completionController.triggerCompletion(
        const CompletionTrigger(kind: CompletionTriggerKind.manual),
      );

      // Give debouncer 100ms to fire
      await tester.pump(const Duration(milliseconds: 100));

      final session = state.completionController.activeSession;
      expect(session, isNotNull);
      expect(session!.items.length, 2);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                CompletionOverlayWidget(
                  session: session,
                  controller: state.completionController,
                  globalX: 50.0,
                  globalY: 100.0,
                ),
              ],
            ),
          ),
        ),
      );

      // Verify the list shows the items
      expect(find.text('print'), findsOneWidget);
      expect(find.text('printError'), findsOneWidget);
      expect(find.text('print message'), findsNWidgets(2));

      // Tap on print item to select it
      await tester.tap(find.text('print'));
      await tester.pump();

      // Session should close and prefix 'pr' in document should be replaced by 'print()'
      expect(state.completionController.activeSession, isNull);
      expect(doc.content, 'void main() {\n  print()\n}');
    });
  });
}
