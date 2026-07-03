import '../contracts/ai_provider.dart';
import 'provider_health.dart';
import '../models/ai_request.dart';
import '../models/ai_response.dart';

class BaselineProvider implements AIProvider {
  final AIProvider _fallback;

  BaselineProvider(this._fallback);

  @override
  String get name => "baseline-provider";

  @override
  ProviderHealth get health => _fallback.health;

  @override
  Future<AIResponse> execute(AIRequest request) async {
    return await _fallback.execute(request);
  }

  @override
  Stream<String> executeStream(AIRequest request) {
    return _fallback.executeStream(request);
  }
}
