import '../../models/capability.dart';
import '../../models/model_metadata.dart';
import '../../providers/provider_health.dart';
import '../../registry/provider_manifest.dart';
import 'gemini_models.dart';

class GeminiManifest {
  static const ProviderManifest manifest = ProviderManifest(
    providerName: "gemini",
    providerVersion: "1.5",
    supportedModels: [
      ModelMetadata(
        name: GeminiModels.flash,
        contextWindow: 1048576,
        maxOutputTokens: 8192,
        pricingInputPerMillion: 0.075,
        pricingOutputPerMillion: 0.30,
        capabilities: {
          Capability.text,
          Capability.vision,
          Capability.streaming,
          Capability.json,
        },
        latencyTier: "low",
        providerName: "gemini",
      ),
      ModelMetadata(
        name: GeminiModels.pro,
        contextWindow: 2097152,
        maxOutputTokens: 8192,
        pricingInputPerMillion: 3.50,
        pricingOutputPerMillion: 10.50,
        capabilities: {
          Capability.text,
          Capability.vision,
          Capability.streaming,
          Capability.json,
          Capability.toolCalling,
          Capability.reasoning,
        },
        latencyTier: "high",
        providerName: "gemini",
      ),
    ],
    capabilities: {
      Capability.text,
      Capability.vision,
      Capability.streaming,
      Capability.json,
      Capability.toolCalling,
      Capability.reasoning,
    },
    supportsStreaming: true,
    supportsJson: true,
    initialHealth: ProviderHealth.healthy,
  );
}
