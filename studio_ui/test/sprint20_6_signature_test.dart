import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/core/state/studio_state.dart';
import 'package:studio_ui/models/editor_document.dart';
import 'package:studio_ui/models/language_intelligence_models.dart';
import 'package:studio_ui/core/services/language_intelligence_providers.dart';
import 'package:studio_ui/core/services/workbench_providers.dart';
import 'package:studio_ui/core/services/signature_help_cache.dart';
import 'package:studio_ui/features/editor/widgets/signature_help_overlay_widget.dart';
import 'package:studio_ui/features/editor/controllers/signature_help_controller.dart';
import 'package:studio_ui/models/ids.dart';

class TestSignatureHelpProvider implements SignatureHelpProvider {
  @override
  final String id = 'test-signature';
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
  Future<OperationResult<SignatureHelp>> provideSignatureHelp(
    ProviderExecutionContext context,
  ) async {
    return const OperationResult.ok(
      SignatureHelp(
        signatures: [
          SignatureInformation(
            label: 'showDialog(BuildContext context, WidgetBuilder builder)',
            documentation:
                'Displays a Material dialog above the current contents.',
            parameters: [
              ParameterInformation(
                label: 'BuildContext context',
                documentation: 'Context description',
              ),
              ParameterInformation(
                label: 'WidgetBuilder builder',
                documentation: 'Builder description',
              ),
            ],
          ),
        ],
        activeSignature: 0,
        activeParameter: 0,
      ),
    );
  }
}

void main() {
  group('Signature Help Cache and Controller Tests', () {
    test('SignatureHelpCache stores and invalidates correctly', () {
      final cache = SignatureHelpCache();
      const help = SignatureHelp(
        signatures: [
          SignatureInformation(
            label: 'print(Object? object)',
            parameters: [ParameterInformation(label: 'Object? object')],
          ),
        ],
      );

      cache.put('ws1', 'lib/main.dart', 1, 'print', help);

      final cached = cache.get('ws1', 'lib/main.dart', 1, 'print');
      expect(cached, isNotNull);
      expect(cached!.signatures.first.label, equals('print(Object? object)'));

      cache.invalidatePath('lib/main.dart');
      expect(cache.get('ws1', 'lib/main.dart', 1, 'print'), isNull);
    });

    testWidgets(
      'SignatureHelpOverlayWidget renders parameters and highlights active',
      (WidgetTester tester) async {
        final state = StudioState();
        state.connect(18080);

        await state.languageRegistry.registerSignatureHelpProvider(
          'dart',
          TestSignatureHelpProvider(),
        );

        final doc = EditorDocument(
          id: 'lib/main.dart',
          path: 'lib/main.dart',
          name: 'main.dart',
          content: 'void main() {\n  showDialog(\n}',
          language: 'dart',
          encoding: 'utf8',
          lastModified: '',
          readOnly: false,
        );
        state.editor.open(doc);
        state.documentService.cacheDocument(DocumentId('lib/main.dart'), doc);
        doc.updateCursor(const Position(line: 2, column: 14));

        state.signatureHelpController.triggerSignatureHelp(
          SignatureTriggerKind.automatic,
        );

        await tester.pump(const Duration(milliseconds: 100));

        final session = state.signatureHelpController.activeSession;
        expect(session, isNotNull);
        expect(session!.help.signatures.first.label, contains('showDialog'));

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  SignatureHelpOverlayWidget(
                    session: session,
                    controller: state.signatureHelpController,
                    globalX: 50.0,
                    globalY: 100.0,
                  ),
                ],
              ),
            ),
          ),
        );

        expect(find.textContaining('showDialog'), findsOneWidget);
        expect(find.textContaining('BuildContext context'), findsNWidgets(2));
        expect(find.textContaining('Context description'), findsOneWidget);
      },
    );
  });
}
