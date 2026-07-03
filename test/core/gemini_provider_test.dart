import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';
import 'package:indiverse_developer_platform/core/models/ai_request.dart';
import 'package:indiverse_developer_platform/core/models/exceptions.dart';
import 'package:indiverse_developer_platform/core/providers/gemini/gemini_adapter.dart';
import 'package:indiverse_developer_platform/core/providers/gemini/gemini_api_client.dart';
import 'package:indiverse_developer_platform/core/security/credential_manager.dart';
import 'package:indiverse_developer_platform/core/security/secret_provider.dart';
import 'package:indiverse_developer_platform/core/security/api_key_manager.dart';

class MockHttpClient extends http.BaseClient {
  final http.Response Function(http.BaseRequest) _handler;
  MockHttpClient(this._handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final res = _handler(request);
    final stream = Stream.value(res.bodyBytes);
    return http.StreamedResponse(stream, res.statusCode, headers: res.headers);
  }
}

void main() {
  group('Gemini Provider Adapter Tests', () {
    late CredentialManager credentialManager;

    setUp(() {
      final apiKeyManager = ApiKeyManager();
      apiKeyManager.addProvider(EnvironmentSecretProvider({
        "GEMINI_API_KEY": "fake-api-key",
      }));
      credentialManager = CredentialManager(apiKeyManager: apiKeyManager);
    });

    test('should execute request and map response successfully', () async {
      final mockClient = MockHttpClient((req) {
        expect(req.url.path, contains("generateContent"));
        expect(req.url.queryParameters["key"], equals("fake-api-key"));

        final responseBody = {
          "candidates": [
            {
              "content": {
                "parts": [
                  {"text": "Hello user, how can I help?"}
                ]
              },
              "finishReason": "STOP"
            }
          ],
          "usageMetadata": {
            "promptTokenCount": 10,
            "candidatesTokenCount": 20,
            "totalTokenCount": 30
          }
        };
        return http.Response(jsonEncode(responseBody), 200);
      });

      final apiClient = GeminiApiClient(client: mockClient);
      final adapter = GeminiAdapter(
          apiClient: apiClient, credentialManager: credentialManager);

      final response = await adapter.execute(const AIRequest(
        prompt: "Hi",
        modelName: "gemini-1.5-flash",
      ));

      expect(response.text, equals("Hello user, how can I help?"));
      expect(response.usage.inputTokens, equals(10));
      expect(response.usage.outputTokens, equals(20));
      expect(response.finishReason, equals("stop"));
    });

    test('should map HTTP 429 status code to RateLimitException', () async {
      final mockClient = MockHttpClient((req) {
        return http.Response("Resource Exhausted", 429);
      });

      final apiClient = GeminiApiClient(client: mockClient);
      final adapter = GeminiAdapter(
          apiClient: apiClient, credentialManager: credentialManager);

      expect(
        () => adapter.execute(const AIRequest(
          prompt: "Hi",
          modelName: "gemini-1.5-flash",
        )),
        throwsA(isA<RateLimitException>()),
      );
    });

    test('should map HTTP 401 status code to AuthenticationException',
        () async {
      final mockClient = MockHttpClient((req) {
        return http.Response("API Key Invalid", 401);
      });

      final apiClient = GeminiApiClient(client: mockClient);
      final adapter = GeminiAdapter(
          apiClient: apiClient, credentialManager: credentialManager);

      expect(
        () => adapter.execute(const AIRequest(
          prompt: "Hi",
          modelName: "gemini-1.5-flash",
        )),
        throwsA(isA<AuthenticationException>()),
      );
    });
  });
}
