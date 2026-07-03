import '../models/ai_request.dart';
import '../models/ai_response.dart';

import '../providers/provider_health.dart';

abstract class AIProvider {
  String get name;
  ProviderHealth get health;
  Future<AIResponse> execute(AIRequest request);
  Stream<String> executeStream(AIRequest request);
}
