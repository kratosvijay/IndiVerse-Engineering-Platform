import '../contracts/ai_provider.dart';

class ProviderRegistry {
  final Map<String, AIProvider> _providers = {};

  List<String> get registeredProviders =>
      _providers.values.map((p) => p.name).toSet().toList();

  void registerProvider(String modelName, AIProvider provider) {
    _providers[modelName] = provider;
  }

  AIProvider resolve(String modelName) {
    final provider = _providers[modelName];
    if (provider == null) {
      throw StateError("No AIProvider registered for model: $modelName");
    }
    return provider;
  }
}
