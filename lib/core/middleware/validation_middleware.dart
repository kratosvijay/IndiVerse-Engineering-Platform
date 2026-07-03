import 'middleware.dart';
import '../models/ai_request.dart';
import '../models/ai_response.dart';

class ValidationMiddleware implements Middleware {
  @override
  Future<AIResponse> next(AIRequest request,
      Future<AIResponse> Function(AIRequest) nextHandler) async {
    if (request.prompt.trim().isEmpty) {
      throw ArgumentError("Request prompt cannot be empty.");
    }
    return await nextHandler(request);
  }
}
