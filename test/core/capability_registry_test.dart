import 'package:test/test.dart';
import 'package:indiverse_developer_platform/core/registry/model_registry.dart';
import 'package:indiverse_developer_platform/core/models/model_metadata.dart';
import 'package:indiverse_developer_platform/core/models/capability.dart';

void main() {
  group('Capability Registry Routing Tests', () {
    test('should resolve models supporting specific capability', () {
      final registry = ModelRegistry();

      registry.registerModel(const ModelMetadata(
        name: "vision-model",
        contextWindow: 16384,
        maxOutputTokens: 4096,
        pricingInputPerMillion: 1.5,
        pricingOutputPerMillion: 3.0,
        capabilities: {Capability.text, Capability.vision},
        latencyTier: "medium",
        providerName: "mock",
      ));

      registry.registerModel(const ModelMetadata(
        name: "text-only-model",
        contextWindow: 8192,
        maxOutputTokens: 2048,
        pricingInputPerMillion: 0.5,
        pricingOutputPerMillion: 1.0,
        capabilities: {Capability.text},
        latencyTier: "low",
        providerName: "mock",
      ));

      final visionModels = registry.getModelsByCapability(Capability.vision);
      expect(visionModels.length, 1);
      expect(visionModels.first.name, "vision-model");

      final textModels = registry.getModelsByCapability(Capability.text);
      expect(textModels.length, 2);
    });
  });
}
