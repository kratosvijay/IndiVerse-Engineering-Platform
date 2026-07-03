import '../contracts/ai_provider.dart';
import 'provider_health.dart';
import '../models/ai_request.dart';
import '../models/ai_response.dart';
import '../models/ai_chunk.dart';
import '../models/model_metadata.dart';
import '../registry/provider_manifest.dart';

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
  Stream<AIChunk> executeStream(AIRequest request) {
    return _fallback.executeStream(request);
  }

  @override
  ProviderManifest manifest() => _fallback.manifest();

  @override
  Future<List<ModelMetadata>> discoverModels() => _fallback.discoverModels();
}
