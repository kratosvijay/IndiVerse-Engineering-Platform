import 'package:test/test.dart';
import 'package:indiverse_developer_platform/core/events/event_bus.dart';
import 'package:indiverse_developer_platform/core/events/runtime_event.dart';
import 'package:indiverse_developer_platform/core/models/ai_request.dart';
import 'package:indiverse_developer_platform/core/runtime/runtime.dart';
import 'package:indiverse_developer_platform/core/registry/provider_registry.dart';
import 'package:indiverse_developer_platform/core/providers/mock_provider.dart';

void main() {
  group('Runtime Pipeline and Events Tests', () {
    test('should execute request and publish lifecycle events', () async {
      final bus = EventBus();
      final providerRegistry = ProviderRegistry();
      final mockProv = MockProvider(name: "mock-provider");
      providerRegistry.registerProvider("mock-model", mockProv);

      final runtime = Runtime(
        providerRegistry: providerRegistry,
        eventBus: bus,
      );

      final events = <RuntimeEvent>[];
      final sub = bus.stream.listen(events.add);

      const request = AIRequest(
        prompt: "Hello core AI",
        modelName: "mock-model",
      );

      final result = await runtime.execute(request);

      expect(result.providerName, "mock-provider");
      expect(result.response.text, contains("Mock response text"));

      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Verify events are published
      expect(events.length, greaterThanOrEqualTo(3));
      expect(events[0], isA<RuntimeStarted>());
      expect(events[1], isA<ProviderSelected>());
      expect(events[2], isA<RuntimeCompleted>());

      await sub.cancel();
    });
  });
}
