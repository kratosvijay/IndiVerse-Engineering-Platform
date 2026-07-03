import '../models/ai_request.dart';
import '../models/ai_response.dart';

abstract class AIPlugin {
  String get name;
  Future<AIRequest> beforeExecute(AIRequest request);
  Future<AIResponse> afterExecute(AIResponse response);
}
