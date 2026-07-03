import 'package:test/test.dart';
import 'package:indiverse_developer_platform/core/events/event_bus.dart';
import 'package:indiverse_developer_platform/core/events/runtime_event.dart';
import 'package:indiverse_developer_platform/core/models/ai_response.dart';
import 'package:indiverse_developer_platform/core/models/execution_result.dart';
import 'package:indiverse_developer_platform/core/tracking/token_tracker.dart';

void main() {
  group('TokenTracker Tests', () {
    test('should accumulate total tokens from completed events', () async {
      final bus = EventBus();
      final tracker = TokenTracker(eventBus: bus);

      final event = RuntimeCompleted(
        timestamp: DateTime.now(),
        eventId: "test-event",
        result: const ExecutionResult(
          latency: Duration.zero,
          retries: 0,
          errors: [],
          providerName: "mock",
          response: AIResponse(
            text: "Output",
            usage: TokenUsage(
                inputTokens: 10, outputTokens: 20, reasoningTokens: 5),
            finishReason: "stop",
          ),
        ),
      );

      bus.publish(event);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(tracker.totalInputTokens, 10);
      expect(tracker.totalOutputTokens, 20);
      expect(tracker.totalReasoningTokens, 5);
      expect(tracker.totalTokens, 30);

      tracker.dispose();
    });
  });
}
