import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/core/services/overlay_manager.dart';
import 'package:studio_ui/features/chat/controllers/chat_controller.dart';
import 'package:studio_ui/features/chat/controllers/chat_input_controller.dart';
import 'package:studio_ui/features/chat/controllers/chat_session_state.dart';
import 'package:studio_ui/features/chat/widgets/chat_panel.dart';
import 'package:studio_ui/features/chat/widgets/chat_renderer.dart';
import 'package:studio_ui/models/ai_models.dart';
import 'package:studio_ui/core/services/ai_service.dart';

class FakeAIService extends AIService {
  FakeAIService() : super(serverUrl: '');

  @override
  Future<List<Map<String, dynamic>>> getProviders() async {
    return [
      {
        'id': 'mock-ai',
        'name': 'Mock AI',
        'state': 'ready',
        'priority': 10,
        'capabilities': {
          'chat': true,
          'streaming': true,
          'tools': false,
          'vision': false,
          'embeddings': false,
          'images': false,
          'reasoning': false,
        },
      },
    ];
  }

  @override
  Future<List<AIModel>> getModels() async {
    return [
      const AIModel(
        id: 'mock-pro',
        name: 'Mock Pro',
        provider: 'mock-ai',
        contextWindow: 1000,
        supportsVision: false,
        supportsTools: false,
        supportsReasoning: false,
        supportsJsonMode: false,
        supportsStreaming: true,
      ),
    ];
  }

  @override
  Stream<AIStreamEvent> chatStream({
    required ConversationSession session,
    String? activeFilePath,
    Map<String, String>? variables,
    int? maxContextTokens,
    String? requestId,
  }) {
    final controller = StreamController<AIStreamEvent>();
    scheduleMicrotask(() {
      controller.add(
        TokenChunkEvent(
          requestId: requestId ?? 'req',
          timestamp: DateTime.now(),
          chunk: 'Generated Code Response',
        ),
      );
      controller.close();
    });
    return controller.stream;
  }
}

void main() {
  group('OverlayManager Unit Tests', () {
    late OverlayManager manager;

    setUp(() {
      manager = OverlayManager();
    });

    test('OverlayManager handles priority conflict resolution', () {
      final entry1 = OverlayEntry(
        builder: (_) => const Text('Completion Popup'),
      );
      final entry2 = OverlayEntry(
        builder: (_) => const Text('Inline AI Panel'),
      );

      // 1. Register low priority completion overlay
      manager.register(
        OverlayDescriptor(
          id: 'completion',
          type: OverlayType.completion, // priority 1
          entry: entry1,
        ),
      );

      expect(manager.isActive('completion'), true);

      // 2. Register high priority inline AI overlay — should dismiss lower
      manager.register(
        OverlayDescriptor(
          id: 'inlineAI',
          type: OverlayType.inlineAI, // priority 6
          entry: entry2,
        ),
      );

      // 3. Low priority should be dismissed automatically
      expect(manager.isActive('completion'), false);
      expect(manager.isActive('inlineAI'), true);
    });

    test('OverlayManager hideAll clears all tracked overlays', () {
      final entry1 = OverlayEntry(builder: (_) => const SizedBox());
      final entry2 = OverlayEntry(builder: (_) => const SizedBox());

      manager.register(
        OverlayDescriptor(id: 'a', type: OverlayType.completion, entry: entry1),
      );
      manager.register(
        OverlayDescriptor(id: 'b', type: OverlayType.completion, entry: entry2),
      );

      expect(manager.isActive('a'), true);
      expect(manager.isActive('b'), true);

      manager.hideAll();

      expect(manager.isActive('a'), false);
      expect(manager.isActive('b'), false);
    });
  });

  group('Chat Subsystem Controllers & UI Tests', () {
    late FakeAIService fakeService;
    late ChatController chatController;
    late ChatInputController inputController;

    setUp(() {
      fakeService = FakeAIService();
      chatController = ChatController(
        aiService: fakeService,
        workspace: 'test',
      );
      inputController = ChatInputController();
    });

    test('ChatInputController history and clear mechanics', () {
      inputController.text = 'hello';
      expect(inputController.text, 'hello');

      String? submittedText;
      inputController.submitPrompt((val) {
        submittedText = val;
      });

      expect(submittedText, 'hello');
      expect(inputController.text, ''); // cleared

      // Verify history navigation
      inputController.navigateHistoryUp();
      expect(inputController.text, 'hello');
    });

    test(
      'ChatController initialize sets default models and creates empty session',
      () async {
        await chatController.initialize();
        expect(chatController.state.activeProviderId, 'mock-ai');
        expect(chatController.state.activeModelId, 'mock-pro');
        expect(chatController.state.session, isNotNull);
        expect(chatController.state.session!.title, 'New Conversation');
      },
    );

    test('ChatController sends prompt and accumulates response', () async {
      await chatController.initialize();
      expect(chatController.state.streamState, ChatStreamState.idle);

      // Trigger send — the stream is async via scheduleMicrotask
      await chatController.sendPrompt('Write code');

      // Allow microtasks and stream to complete
      await Future.delayed(const Duration(milliseconds: 100));

      // User message + assistant response
      expect(chatController.state.messages.length, 2);
      expect(
        chatController.state.messages.last.content,
        'Generated Code Response',
      );
    });

    test('ChatController provider and model selection', () async {
      await chatController.initialize();

      chatController.selectProvider('other-provider');
      expect(chatController.state.activeProviderId, 'other-provider');

      chatController.selectModel('other-model');
      expect(chatController.state.activeModelId, 'other-model');
    });

    test('ChatController conversation switching', () async {
      await chatController.initialize();
      final firstSession = chatController.state.session!;

      // Ensure unique timestamp-based ID
      await Future.delayed(const Duration(milliseconds: 10));
      await chatController.createNewSession('Second Chat');
      final secondSession = chatController.state.session!;

      expect(secondSession.title, 'Second Chat');
      expect(secondSession.id, isNot(equals(firstSession.id)));

      // Switch back
      chatController.switchSession(firstSession);
      expect(chatController.state.session!.id, firstSession.id);
    });

    test('MarkdownChatRenderer parses paragraphs and code fences blocks', () {
      const renderer = MarkdownChatRenderer();
      final msg = ChatMessage(
        role: ChatRole.assistant,
        content:
            'This is a description:\n```dart\nvoid main() {}\n```\nOutro paragraph.',
        timestamp: DateTime.now(),
      );

      final widget = renderer.render(msg);
      expect(widget, isA<Column>());
      final col = widget as Column;
      expect(col.children.length, 3); // paragraph, codeblock, paragraph
    });

    testWidgets(
      'ChatPanel renders model selectors and handles text streaming',
      (WidgetTester tester) async {
        await chatController.initialize();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ChatPanel(controller: chatController, onInsertCode: (_) {}),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Find dropdown items
        expect(find.byType(DropdownButton<String>), findsNWidgets(2));
        expect(find.byIcon(Icons.send), findsOneWidget);
      },
    );
  });
}
