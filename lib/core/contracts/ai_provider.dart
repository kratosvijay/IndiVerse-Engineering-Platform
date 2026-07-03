import '../models/ai_request.dart';
import '../models/ai_response.dart';
import '../models/ai_chunk.dart';
import '../models/model_metadata.dart';
import '../providers/provider_health.dart';
import '../registry/provider_manifest.dart';

abstract class AIProvider {
  String get name;
  ProviderHealth get health;
  Future<AIResponse> execute(AIRequest request);
  Stream<AIChunk> executeStream(AIRequest request);
  ProviderManifest manifest();
  Future<List<ModelMetadata>> discoverModels();
}
