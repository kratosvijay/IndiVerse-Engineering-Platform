import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/features/chat/controllers/chat_controller.dart';
import 'package:studio_ui/features/chat/controllers/chat_session_state.dart';
import 'package:studio_ui/models/ai_models.dart';
import 'package:studio_ui/models/message_metadata.dart';
import 'package:studio_ui/models/request_metrics.dart';
import 'package:studio_ui/core/services/ai_service.dart';

class FakeStreamingAIService extends AIService {
  final StreamController<AIStreamEvent> streamController;

  FakeStreamingAIService(this.streamController) : super(serverUrl: '');

  @override
  Future<List<Map<String, dynamic>>> getProviders() async {
    return [
      {'id': 'mock-ai', 'name': 'Mock AI'},
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
        supportsReasoning: true,
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
    return streamController.stream;
  }
}

void main() {
  group('Auto-Title Generator Tests', () {
    test('generateAutoTitle strips leading punctuation and markdown', () {
      final input = '**Question**: What is the velocity of an unladen swallow?';
      final title = generateAutoTitle(input);
      expect(title, 'Question What is the velocity of an unladen');
    });

    test('generateAutoTitle truncates at word boundaries up to 50 chars', () {
      final input =
          'This is a very long prompt with many words that will exceed the fifty character limit';
      final title = generateAutoTitle(input);
      expect(title.length, lessThanOrEqualTo(50));
      expect(title, 'This is a very long prompt with many words that');
    });

    test('generateAutoTitle handles short prompts without truncation', () {
      final input = 'Hello World!';
      final title = generateAutoTitle(input);
      expect(title, 'Hello World');
    });
  });

  group('RequestMetrics & MessageMetadata Tests', () {
    test('RequestMetrics calculates latencies correctly', () {
      final started = DateTime.now();
      final firstToken = started.add(const Duration(milliseconds: 100));
      final completed = started.add(const Duration(milliseconds: 500));

      final metrics = RequestMetrics(
        requestId: 'req-1',
        started: started,
        firstToken: firstToken,
        completed: completed,
      );

      expect(metrics.latencyMs, 500);
      expect(metrics.ttftMs, 100);
      expect(metrics.streamDurationMs, 400);
    });

    test('MessageMetadata serialization matches', () {
      final meta = MessageMetadata(
        providerId: 'prov',
        modelId: 'mod',
        promptTokens: 10,
        completionTokens: 20,
        latencyMs: 150,
        ttftMs: 50,
        streamDurationMs: 100,
        generatedAt: DateTime(2026, 7, 7),
      );

      final json = meta.toJson();
      final meta2 = MessageMetadata.fromJson(json);

      expect(meta2.providerId, 'prov');
      expect(meta2.modelId, 'mod');
      expect(meta2.promptTokens, 10);
      expect(meta2.completionTokens, 20);
      expect(meta2.latencyMs, 150);
      expect(meta2.ttftMs, 50);
      expect(meta2.streamDurationMs, 100);
      expect(meta2.totalTokens, 30);
    });
  });

  group('ChatController Streaming & State Machine Tests', () {
    test('Tracks RequestStage and RequestMetrics during stream', () async {
      final streamController = StreamController<AIStreamEvent>();
      final fakeService = FakeStreamingAIService(streamController);
      final controller = ChatController(
        aiService: fakeService,
        workspace: 'test',
      );

      await controller.initialize();
      expect(controller.state.streamState, ChatStreamState.idle);

      final List<ChatStreamState> streamStates = [];
      controller.addListener(() {
        streamStates.add(controller.state.streamState);
      });

      // Send prompt
      final sendFuture = controller.sendPrompt('Testing prompt');

      // State should transition to preparing
      expect(controller.state.streamState, ChatStreamState.preparing);
      expect(controller.state.requestStage, RequestStage.preparing);

      // Move forward past waitingProvider
      await Future.delayed(Duration.zero);
      expect(controller.state.streamState, ChatStreamState.waitingFirstToken);
      expect(controller.state.requestStage, RequestStage.waitingProvider);

      // Find the requestId created
      final reqId = controller.requestMetricsMap.keys.first;
      expect(controller.requestMetricsMap[reqId], isNotNull);

      // Emit stage event (gatheringContext)
      streamController.add(
        StageEvent(
          requestId: reqId,
          timestamp: DateTime.now(),
          stage: RequestStage.gatheringContext,
        ),
      );
      await Future.delayed(Duration.zero);
      expect(controller.state.requestStage, RequestStage.gatheringContext);

      // Emit stage event (streaming)
      streamController.add(
        StageEvent(
          requestId: reqId,
          timestamp: DateTime.now(),
          stage: RequestStage.streaming,
        ),
      );
      await Future.delayed(Duration.zero);
      expect(controller.state.requestStage, RequestStage.streaming);
      expect(controller.state.streamState, ChatStreamState.streaming);

      // Emit token chunk
      streamController.add(
        TokenChunkEvent(
          requestId: reqId,
          timestamp: DateTime.now(),
          chunk: 'Hello',
        ),
      );
      await Future.delayed(Duration.zero);
      expect(controller.activeStreamedMessage.value?.content, 'Hello');
      expect(controller.requestMetricsMap[reqId]?.firstToken, isNotNull);

      // Emit reasoning chunk
      streamController.add(
        ReasoningChunkEvent(
          requestId: reqId,
          timestamp: DateTime.now(),
          reasoning: 'Thinking...',
        ),
      );
      await Future.delayed(Duration.zero);
      expect(controller.activeStreamedMessage.value?.reasoning, 'Thinking...');

      // Emit usage
      streamController.add(
        UsageEvent(
          requestId: reqId,
          timestamp: DateTime.now(),
          promptTokens: 15,
          completionTokens: 25,
        ),
      );

      // Emit completed
      streamController.add(
        CompletedEvent(
          requestId: reqId,
          timestamp: DateTime.now(),
          fullText: 'Hello from AI',
          finishReason: FinishReason.stop,
        ),
      );

      // Close stream
      await streamController.close();
      await sendFuture;

      // Ensure fullText overrides accumulated text
      expect(controller.state.messages.last.content, 'Hello from AI');
      expect(controller.state.messages.last.reasoning, 'Thinking...');

      // Metadata should be populated
      final meta = controller.state.messages.last.metadata;
      expect(meta, isNotNull);
      expect(meta!.promptTokens, 15);
      expect(meta.completionTokens, 25);
      expect(meta.latencyMs, isNotNull);
      expect(meta.ttftMs, isNotNull);

      // Check microtask transition to idle
      expect(streamStates, contains(ChatStreamState.completed));
      expect(controller.state.streamState, ChatStreamState.idle);
    });

    test('Draft text is persisted across session switches', () async {
      final streamController = StreamController<AIStreamEvent>();
      final fakeService = FakeStreamingAIService(streamController);
      final controller = ChatController(
        aiService: fakeService,
        workspace: 'test',
      );

      await controller.initialize();
      final session1 = controller.state.session!;

      controller.updateDraft('Unsent draft in session 1');
      expect(controller.getDraft(session1.id), 'Unsent draft in session 1');

      // Wait a bit to ensure a different millisecond timestamp
      await Future.delayed(const Duration(milliseconds: 10));

      await controller.createNewSession('Session 2');
      final session2 = controller.state.session!;

      expect(controller.getDraft(session2.id), '');

      controller.updateDraft('Draft in session 2');
      expect(controller.getDraft(session2.id), 'Draft in session 2');
      expect(controller.getDraft(session1.id), 'Unsent draft in session 1');

      controller.switchSession(session1);
      expect(controller.getDraft(session1.id), 'Unsent draft in session 1');
    });
  });
}
