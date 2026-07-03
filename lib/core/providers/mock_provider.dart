import '../contracts/ai_provider.dart';
import 'provider_health.dart';
import '../models/ai_request.dart';
import '../models/ai_response.dart';
import '../tracking/token_tracker.dart';

class MockProvider implements AIProvider {
  final String _name;

  MockProvider({String name = 'mock-provider'}) : _name = name;

  @override
  String get name => _name;

  @override
  ProviderHealth get health => ProviderHealth.healthy;

  @override
  Future<AIResponse> execute(AIRequest request) async {
    // Return standard dummy response to facilitate test execution
    return AIResponse(
      text: "Mock response text from $name",
      usage: const TokenUsage(
        inputTokens: 100,
        outputTokens: 150,
        totalTokens: 250,
      ),
      finishReason: "stop",
    );
  }

  @override
  Stream<String> executeStream(AIRequest request) async* {
    yield "Mock";
    yield " stream";
    yield " response";
  }
}
