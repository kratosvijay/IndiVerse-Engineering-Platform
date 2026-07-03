import 'middleware.dart';
import '../models/ai_request.dart';
import '../models/ai_response.dart';
import '../events/event_bus.dart';
import '../events/runtime_event.dart';

class RetryMiddleware implements Middleware {
  final int maxRetries;
  final Duration initialDelay;
  final EventBus _eventBus;

  RetryMiddleware({
    this.maxRetries = 3,
    this.initialDelay = const Duration(milliseconds: 100),
    EventBus? eventBus,
  }) : _eventBus = eventBus ?? EventBus();

  @override
  Future<AIResponse> next(AIRequest request,
      Future<AIResponse> Function(AIRequest) nextHandler) async {
    int attempts = 0;
    Duration delay = initialDelay;

    while (true) {
      try {
        return await nextHandler(request);
      } catch (e) {
        attempts++;
        if (attempts > maxRetries) {
          rethrow;
        }

        _eventBus.publish(RetryAttempted(
          timestamp: DateTime.now(),
          eventId: "retry-${DateTime.now().millisecondsSinceEpoch}",
          attempt: attempts,
          error: e.toString(),
          delay: delay,
        ));

        await Future<void>.delayed(delay);
        delay *= 2; // Exponential backoff
      }
    }
  }
}
