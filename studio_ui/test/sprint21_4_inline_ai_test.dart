import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/core/state/studio_state.dart';
import 'package:studio_ui/features/editor/controllers/inline_ai_controller.dart';
import 'package:studio_ui/models/inline_ai_models.dart';
import 'package:studio_ui/core/services/diff_engine.dart';
import 'package:studio_ui/models/editor_document.dart';
import 'package:studio_ui/models/language_intelligence_models.dart';
import 'package:studio_ui/models/ai_models.dart';
import 'package:studio_ui/core/services/ai_service.dart';
import 'package:studio_ui/models/ids.dart';

class FakeAIService extends AIService {
  final StreamController<AIStreamEvent> streamController;

  FakeAIService(this.streamController) : super(serverUrl: '');

  @override
  Future<List<Map<String, dynamic>>> getProviders() async => [];

  @override
  Future<List<AIModel>> getModels() async => [];

  @override
  Stream<AIStreamEvent> chatStream({
    required ConversationSession session,
    String? activeFilePath,
    Map<String, String>? variables,
    int? maxContextTokens,
    String? requestId,
  }) {
    return streamController.stream;
  }
}

void main() {
  group('DiffEngine LCS Tests', () {
    test('correctly identifies unchanged, inserted, and deleted lines', () {
      final original = ['line 1', 'line 2', 'line 3'];
      final current = ['line 1', 'line 2.5', 'line 3', 'line 4'];

      final diff = DiffEngine.computeDiff(original, current);

      expect(diff.length, 5);
      expect(diff[0].type, DiffType.unchanged);
      expect(diff[0].text, 'line 1');

      expect(diff[1].type, DiffType.deleted);
      expect(diff[1].text, 'line 2');

      expect(diff[2].type, DiffType.inserted);
      expect(diff[2].text, 'line 2.5');

      expect(diff[3].type, DiffType.unchanged);
      expect(diff[3].text, 'line 3');

      expect(diff[4].type, DiffType.inserted);
      expect(diff[4].text, 'line 4');
    });
  });

  group('InlineAIController Tests', () {
    late StudioState state;
    late InlineAIController controller;
    late StreamController<AIStreamEvent> streamController;
    late FakeAIService fakeService;

    setUp(() {
      streamController = StreamController<AIStreamEvent>();
      fakeService = FakeAIService(streamController);
      state = StudioState();
      state.aiService = fakeService;
      controller = state.inlineAIController;
    });

    test('triggerInlineAI initializes a session at selection', () async {
      final doc = EditorDocument(
        id: 'file.dart',
        path: 'file.dart',
        name: 'file.dart',
        content: 'void main() {\n  print("hello");\n}',
        language: 'dart',
        encoding: 'utf8',
        lastModified: '',
        readOnly: false,
      );
      state.editor.open(doc);
      state.documentService.cacheDocument(DocumentId('file.dart'), doc);

      doc.updateSelection(SelectionRange(
        start: const Position(line: 2, column: 1),
        end: const Position(line: 2, column: 18),
      ));

      controller.triggerInlineAI();

      expect(controller.activeSession, isNotNull);
      final session = controller.activeSession!;
      expect(session.documentId, 'file.dart');
      expect(session.state, InlineAIState.prompting);
      expect(session.selectionRange.start.line, 2);
    });

    test('submitPrompt runs stream and computes diff upon completion', () async {
      final doc = EditorDocument(
        id: 'file.dart',
        path: 'file.dart',
        name: 'file.dart',
        content: 'void main() {\n  print("hello");\n}',
        language: 'dart',
        encoding: 'utf8',
        lastModified: '',
        readOnly: false,
      );
      state.editor.open(doc);
      state.documentService.cacheDocument(DocumentId('file.dart'), doc);

      doc.updateSelection(SelectionRange(
        start: const Position(line: 2, column: 1),
        end: const Position(line: 2, column: 18),
      ));

      controller.triggerInlineAI();

      final future = controller.submitPrompt('make it print world', InlineAction.edit);

      expect(controller.activeSession!.state, isNot(equals(InlineAIState.prompting)));

      streamController.add(TokenChunkEvent(
        requestId: 'req-1',
        timestamp: DateTime.now(),
        chunk: '  print("world");',
      ));
      await Future.delayed(Duration.zero);

      expect(controller.activeSession!.result, isNotNull);
      expect(controller.activeSession!.result!.previewText, '  print("world");');

      streamController.add(CompletedEvent(
        requestId: 'req-1',
        timestamp: DateTime.now(),
        fullText: '  print("world");',
      ));
      await streamController.close();
      await future;

      expect(controller.activeSession!.state, InlineAIState.reviewing);
      expect(controller.activeSession!.result!.diff.length, 2);
    });

    test('accept applies workspace edits via WorkspaceEditExecutor', () async {
      final doc = EditorDocument(
        id: 'file.dart',
        path: 'file.dart',
        name: 'file.dart',
        content: 'void main() {\n  print("hello");\n}',
        language: 'dart',
        encoding: 'utf8',
        lastModified: '',
        readOnly: false,
      );
      state.editor.open(doc);
      state.documentService.cacheDocument(DocumentId('file.dart'), doc);

      doc.updateSelection(SelectionRange(
        start: const Position(line: 2, column: 1),
        end: const Position(line: 2, column: 18),
      ));

      controller.triggerInlineAI();

      final future = controller.submitPrompt('make it print world', InlineAction.edit);

      streamController.add(CompletedEvent(
        requestId: 'req-1',
        timestamp: DateTime.now(),
        fullText: '  print("world");',
      ));
      await streamController.close();
      await future;

      expect(controller.activeSession!.state, InlineAIState.reviewing);

      await controller.accept();

      expect(doc.content, 'void main() {\n  print("world");\n}');
      expect(controller.activeSession, isNull);
    });

    test('reject discards changes', () async {
      final doc = EditorDocument(
        id: 'file.dart',
        path: 'file.dart',
        name: 'file.dart',
        content: 'void main() {\n  print("hello");\n}',
        language: 'dart',
        encoding: 'utf8',
        lastModified: '',
        readOnly: false,
      );
      state.editor.open(doc);
      state.documentService.cacheDocument(DocumentId('file.dart'), doc);

      doc.updateSelection(SelectionRange(
        start: const Position(line: 2, column: 1),
        end: const Position(line: 2, column: 18),
      ));

      controller.triggerInlineAI();

      final future = controller.submitPrompt('make it print world', InlineAction.edit);

      streamController.add(CompletedEvent(
        requestId: 'req-1',
        timestamp: DateTime.now(),
        fullText: '  print("world");',
      ));
      await streamController.close();
      await future;

      controller.reject();

      expect(doc.content, 'void main() {\n  print("hello");\n}');
      expect(controller.activeSession, isNull);
    });
  });
}
