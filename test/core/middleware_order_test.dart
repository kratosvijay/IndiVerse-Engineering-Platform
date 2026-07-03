import 'package:test/test.dart';
import 'package:indiverse_developer_platform/core/middleware/middleware.dart';
import 'package:indiverse_developer_platform/core/models/ai_request.dart';
import 'package:indiverse_developer_platform/core/models/ai_response.dart';
import 'package:indiverse_developer_platform/core/runtime/pipeline.dart';
import 'package:indiverse_developer_platform/core/tracking/token_tracker.dart';

class OrderTrackingMiddleware implements Middleware {
  final String name;
  final List<String> orderList;

  OrderTrackingMiddleware(this.name, this.orderList);

  @override
  Future<AIResponse> next(AIRequest request,
      Future<AIResponse> Function(AIRequest) nextHandler) async {
    orderList.add("before-$name");
    final response = await nextHandler(request);
    orderList.add("after-$name");
    return response;
  }
}

void main() {
  group('Middleware Execution Order Tests', () {
    test('should execute middleware in registered sequence', () async {
      final list = <String>[];
      final pipeline = Pipeline();
      pipeline.add(OrderTrackingMiddleware("first", list));
      pipeline.add(OrderTrackingMiddleware("second", list));

      const request = AIRequest(prompt: "test", modelName: "mock");
      await pipeline.execute(request, (req) async {
        list.add("endpoint");
        return const AIResponse(
            text: "success", usage: TokenUsage(), finishReason: "stop");
      });

      expect(list, [
        "before-first",
        "before-second",
        "endpoint",
        "after-second",
        "after-first"
      ]);
    });
  });
}
