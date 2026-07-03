import '../models/capability.dart';
import '../models/model_metadata.dart';
import '../providers/provider_health.dart';

class ProviderManifest {
  final String providerName;
  final String providerVersion;
  final List<ModelMetadata> supportedModels;
  final Set<Capability> capabilities;
  final bool supportsStreaming;
  final bool supportsJson;
  final ProviderHealth initialHealth;

  const ProviderManifest({
    required this.providerName,
    required this.providerVersion,
    required this.supportedModels,
    required this.capabilities,
    required this.supportsStreaming,
    required this.supportsJson,
    required this.initialHealth,
  });
}
