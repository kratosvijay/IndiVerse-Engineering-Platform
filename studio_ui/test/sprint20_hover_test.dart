import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/features/editor/widgets/editor_widget.dart';
import 'package:studio_ui/core/state/studio_state.dart';
import 'package:studio_ui/models/editor_document.dart';
import 'package:studio_ui/models/language_intelligence_models.dart';
import 'package:studio_ui/core/services/language_intelligence_providers.dart';
import 'package:studio_ui/models/ids.dart';
import 'package:flutter/gestures.dart';
import 'package:studio_ui/core/services/workbench_providers.dart';

class TestHoverProvider implements HoverProvider {
  @override
  final String id = 'test-hover';
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
  Future<OperationResult<Hover>> provideHover(
    ProviderExecutionContext context,
  ) async {
    return const OperationResult.ok(
      Hover(contents: '**TestSymbol**\n- Description inline\n- Code: `void main()`'),
    );
  }
}

void main() {
  testWidgets('Hover presentation triggers and renders markdown tooltip overlay', (
    WidgetTester tester,
  ) async {
    final state = StudioState();
    state.connect(18080);

    // Register test hover provider
    await state.languageRegistry.registerHoverProvider('dart', TestHoverProvider());

    // Create a mock doc
    final doc = EditorDocument(
      id: 'test.dart',
      path: 'test.dart',
      name: 'test.dart',
      content: 'void main() { print("hello"); }',
      language: 'dart',
      encoding: 'utf8',
      lastModified: '',
      readOnly: false,
    );
    state.editor.open(doc);
    state.documentService.cacheDocument(DocumentId(doc.path), doc);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 600,
            width: 800,
            child: EditorWidget(state: state),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify editor text canvas is mounted
    expect(find.byType(CustomPaint), findsWidgets);

    // Simulates hover gesture at (120, 20.0) which maps to "main"
    // Gutter width is 52.0, text padding is 12.0.
    // Offset X = 120.0 => textX = 120.0 - 52.0 - 12.0 = 56.0.
    // charWidth = 7.2 => col = (56.0 / 7.2).round() + 1 = 8 + 1 = 9 => maps to "main"
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: const Offset(0.0, 0.0));

    await tester.runAsync(() async {
      await gesture.moveTo(const Offset(120.0, 109.0));
      await Future.delayed(const Duration(milliseconds: 250));
    });

    await tester.pumpAndSettle();

    // Verify loading indicator/tooltip overlay appears
    expect(find.byType(CircularProgressIndicator), findsNothing);
    
    // Verify markdown rich spans were rendered
    expect(find.text('TestSymbol'), findsOneWidget);
    expect(find.text('• '), findsNWidgets(2));
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is RichText &&
            w.text.toPlainText().contains('Description inline'),
      ),
      findsOneWidget,
    );
  });
}
