import 'dart:async';
import '../../contracts/ai_provider.dart';
import '../../models/ai_request.dart';
import '../../models/ai_response.dart';
import '../../models/ai_chunk.dart';
import '../../models/model_metadata.dart';
import '../../providers/provider_health.dart';
import '../../security/credential_manager.dart';
import '../../registry/provider_manifest.dart';
import 'gemini_api_client.dart';
import 'gemini_request_mapper.dart';
import 'gemini_response_mapper.dart';
import 'gemini_manifest.dart';
import 'gemini_stream_adapter.dart';

class GeminiAdapter implements AIProvider {
  final GeminiApiClient _apiClient;
  final CredentialManager _credentialManager;

  ProviderHealth _health = ProviderHealth.healthy;

  GeminiAdapter({
    GeminiApiClient? apiClient,
    CredentialManager? credentialManager,
  })  : _apiClient = apiClient ?? GeminiApiClient(),
        _credentialManager = credentialManager ?? CredentialManager();

  @override
  String get name => "gemini";

  @override
  ProviderHealth get health => _health;

  void setHealth(ProviderHealth health) {
    _health = health;
  }

  Future<String> _getApiKey() async {
    final key = await _credentialManager.resolveCredentials("gemini");
    if (key.isEmpty) {
      throw StateError(
          "GEMINI_API_KEY is not configured in CredentialManager.");
    }
    return key;
  }

  @override
  Future<AIResponse> execute(AIRequest request) async {
    final apiKey = await _getApiKey();
    final body = GeminiRequestMapper.mapRequest(request);

    try {
      final json = await _apiClient.generateContent(
        apiKey: apiKey,
        modelName: request.modelName,
        requestBody: body,
      );
      return GeminiResponseMapper.mapResponse(json);
    } catch (e) {
      if (e.toString().contains("RateLimitException")) {
        setHealth(ProviderHealth.rateLimited);
      }
      rethrow;
    }
  }

  @override
  Stream<AIChunk> executeStream(AIRequest request) {
    final controller = StreamController<AIChunk>();

    _getApiKey().then((apiKey) {
      final body = GeminiRequestMapper.mapRequest(request);
      final byteStream = _apiClient.generateContentStream(
        apiKey: apiKey,
        modelName: request.modelName,
        requestBody: body,
      );

      GeminiStreamAdapter.parseStream(byteStream).listen(
        controller.add,
        onError: (Object e) {
          if (e.toString().contains("RateLimitException")) {
            setHealth(ProviderHealth.rateLimited);
          }
          controller.addError(e);
        },
        onDone: controller.close,
        cancelOnError: true,
      );
    }).catchError((Object e) {
      controller.addError(e);
      controller.close();
    });

    return controller.stream;
  }

  @override
  ProviderManifest manifest() {
    return GeminiManifest.manifest;
  }

  @override
  Future<List<ModelMetadata>> discoverModels() async {
    return GeminiManifest.manifest.supportedModels;
  }
}
