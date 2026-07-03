import 'package:test/test.dart';
import 'package:indiverse_developer_platform/core/events/event_bus.dart';
import 'package:indiverse_developer_platform/core/events/runtime_event.dart';
import 'package:indiverse_developer_platform/core/models/ai_response.dart';
import 'package:indiverse_developer_platform/core/models/execution_result.dart';
import 'package:indiverse_developer_platform/core/models/model_metadata.dart';
import 'package:indiverse_developer_platform/core/models/capability.dart';
import 'package:indiverse_developer_platform/core/registry/model_registry.dart';
import 'package:indiverse_developer_platform/core/tracking/token_tracker.dart';
import 'package:indiverse_developer_platform/core/tracking/cost_tracker.dart';

void main() {
  group('CostTracker Tests', () {
    test('should compute cost based on model registry rates', () async {
      final bus = EventBus();
      final registry = ModelRegistry();
      registry.registerModel(const ModelMetadata(
        name: "test-model",
        contextWindow: 8192,
        maxOutputTokens: 2048,
        pricingInputPerMillion: 1.0, // $1.00 per million
        pricingOutputPerMillion: 2.0, // $2.00 per million
        capabilities: {Capability.text},
        latencyTier: "low",
        providerName: "mock-prov",
      ));

      final tracker = CostTracker(eventBus: bus, modelRegistry: registry);

      final event = RuntimeCompleted(
        timestamp: DateTime.now(),
        eventId: "test-event",
        result: const ExecutionResult(
          latency: Duration.zero,
          retries: 0,
          errors: [],
          providerName: "mock-prov",
          response: AIResponse(
            text: "test-model", // using model name here as fallback payload key
            usage: TokenUsage(
                inputTokens: 1000000, outputTokens: 1000000), // 1M tokens each
            finishReason: "stop",
          ),
        ),
      );

      bus.publish(event);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Cost calculation: (1M * 1.0) / 1M + (1M * 2.0) / 1M = 1.0 + 2.0 = $3.00
      expect(tracker.totalCost, closeTo(3.0, 0.001));

      tracker.dispose();
    });
  });
}
