import 'dart:async';
import 'ai_provider.dart';
import 'ai_stream_events.dart';
import '../prompt/prompt_pipeline.dart';

class MockAIProvider implements AIChatProvider {
  @override
  final String id = 'mock-ai';
  @override
  final String name = 'Mock AI Assistant';
  @override
  final int priority = 10;

  AIProviderState _state = AIProviderState.initializing;
  @override
  AIProviderState get state => _state;

  @override
  final AIProviderMetrics metrics = AIProviderMetrics();

  @override
  final AIProviderCapabilities capabilities = const AIProviderCapabilities(
    chat: true,
    streaming: true,
    tools: true,
    reasoning: true,
    vision: true,
  );

  DateTime _lastSuccess = DateTime.now();

  @override
  Future<void> initialize(AIProviderConfiguration config) async {
    _state = AIProviderState.authenticating;
    await Future<void>.delayed(const Duration(milliseconds: 100));
    _state = AIProviderState.ready;
    _lastSuccess = DateTime.now();
  }

  @override
  Future<List<AIModel>> models() async {
    return [
      const AIModel(
        id: 'mock-pro',
        name: 'Mock Pro',
        provider: 'mock-ai',
        contextWindow: 1000000,
        supportsVision: true,
        supportsTools: true,
        supportsReasoning: true,
        supportsJsonMode: true,
        supportsStreaming: true,
      ),
      const AIModel(
        id: 'mock-flash',
        name: 'Mock Flash',
        provider: 'mock-ai',
        contextWindow: 1000000,
        supportsVision: false,
        supportsTools: true,
        supportsReasoning: false,
        supportsJsonMode: true,
        supportsStreaming: true,
      ),
    ];
  }

  @override
  AIProviderHealth getHealth() {
    return AIProviderHealth(
      state: _state,
      averageLatency: metrics.averageLatency,
      lastSuccessfulRequest: _lastSuccess,
      consecutiveFailures: _state == AIProviderState.failed ? 1 : 0,
    );
  }

  @override
  Future<Stream<AIStreamEvent>> chat(AIRequest request) async {
    metrics.requestCount++;
    final controller = StreamController<AIStreamEvent>();
    final stopwatch = Stopwatch()..start();

    // Run async generation
    scheduleMicrotask(() async {
      try {
        final requestId = 'req-${DateTime.now().millisecondsSinceEpoch}';
        final isReasoning = request.session.modelId == 'mock-pro';

        // 1. Simulate TTFT
        await Future<void>.delayed(const Duration(milliseconds: 150));
        if (request.token.isCancelled) {
          metrics.cancelledRequests++;
          controller.close();
          return;
        }
        metrics.totalTtf +=
            Duration(milliseconds: stopwatch.elapsedMilliseconds);

        // 2. Stream Reasoning Chunk if reasoning model
        if (isReasoning) {
          controller.add(ReasoningChunkEvent(
            requestId: requestId,
            timestamp: DateTime.now(),
            reasoning:
                'Thinking: Processing request and active workspace context...',
          ));
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }

        // 3. Stream Response text
        final responseText =
            'Hello! I am your Mock AI assistant. I received your user prompt: "${request.promptPackage.userPrompt}".';
        final words = responseText.split(' ');
        String currentFullText = '';

        for (final word in words) {
          if (request.token.isCancelled) {
            metrics.cancelledRequests++;
            controller.close();
            return;
          }
          final chunk = '$word ';
          currentFullText += chunk;
          controller.add(TokenChunkEvent(
            requestId: requestId,
            timestamp: DateTime.now(),
            chunk: chunk,
          ));
          metrics.completionTokens += 2; // Simulated token count
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }

        // 4. Usage metrics
        final promptEst =
            TokenEstimator.estimate(request.promptPackage.userPrompt);
        metrics.promptTokens += promptEst;
        controller.add(UsageEvent(
          requestId: requestId,
          timestamp: DateTime.now(),
          promptTokens: promptEst,
          completionTokens: words.length * 2,
        ));

        // 5. Completed
        controller.add(CompletedEvent(
          requestId: requestId,
          timestamp: DateTime.now(),
          fullText: currentFullText.trim(),
        ));

        metrics.successCount++;
        _lastSuccess = DateTime.now();
        stopwatch.stop();
        metrics.totalLatency +=
            Duration(milliseconds: stopwatch.elapsedMilliseconds);
        metrics.totalStreamDuration +=
            Duration(milliseconds: stopwatch.elapsedMilliseconds);
      } catch (e) {
        metrics.failedCount++;
        controller.add(ErrorEvent(
          requestId: 'err',
          timestamp: DateTime.now(),
          code: 'STREAM_FAILED',
          message: e.toString(),
        ));
      } finally {
        await controller.close();
      }
    });

    return controller.stream;
  }
}
