import 'capability.dart';

class ModelMetadata {
  final String name;
  final int contextWindow;
  final int maxOutputTokens;
  final double pricingInputPerMillion; // in USD
  final double pricingOutputPerMillion; // in USD
  final Set<Capability> capabilities;
  final String latencyTier; // e.g. "low", "medium", "high"
  final String providerName;

  const ModelMetadata({
    required this.name,
    required this.contextWindow,
    required this.maxOutputTokens,
    required this.pricingInputPerMillion,
    required this.pricingOutputPerMillion,
    required this.capabilities,
    required this.latencyTier,
    required this.providerName,
  });

  bool hasCapability(Capability capability) =>
      capabilities.contains(capability);
}
