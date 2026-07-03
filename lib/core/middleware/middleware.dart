import '../models/ai_request.dart';
import '../models/ai_response.dart';

abstract class Middleware {
  Future<AIResponse> next(
      AIRequest request, Future<AIResponse> Function(AIRequest) nextHandler);
}
