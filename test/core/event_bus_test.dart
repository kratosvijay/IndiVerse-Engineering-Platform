import 'package:test/test.dart';
import 'package:indiverse_developer_platform/core/events/event_bus.dart';
import 'package:indiverse_developer_platform/core/events/runtime_event.dart';
import 'package:indiverse_developer_platform/core/models/ai_request.dart';

void main() {
  group('EventBus Tests', () {
    test('should publish and dispatch event types correctly', () async {
      final bus = EventBus();
      final received = <RuntimeEvent>[];

      final sub = bus.on<RuntimeStarted>().listen(received.add);

      final event = RuntimeStarted(
        timestamp: DateTime.now(),
        eventId: "test-id",
        request: const AIRequest(prompt: "Hello", modelName: "mock"),
      );

      bus.publish(event);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(received.length, 1);
      expect(received.first.eventId, "test-id");

      await sub.cancel();
    });
  });
}
