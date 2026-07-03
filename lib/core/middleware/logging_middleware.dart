import 'middleware.dart';
import '../models/ai_request.dart';
import '../models/ai_response.dart';

class LoggingMiddleware implements Middleware {
  @override
  Future<AIResponse> next(AIRequest request,
      Future<AIResponse> Function(AIRequest) nextHandler) async {
    print("[Pipeline Log] Invoking model: ${request.modelName}");
    final response = await nextHandler(request);
    print(
        "[Pipeline Log] Invocation completed. Length: ${response.text.length}");
    return response;
  }
}
