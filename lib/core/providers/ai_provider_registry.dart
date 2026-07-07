import 'ai_provider.dart';

class AIProviderRegistry {
  final Map<String, AIProvider> _providers = {};

  void registerProvider(AIProvider provider) {
    _providers[provider.id] = provider;
  }

  void unregisterProvider(String id) {
    _providers.remove(id);
  }

  AIProvider? getProvider(String id) {
    return _providers[id];
  }

  List<AIProvider> listProviders() {
    return _providers.values.toList();
  }

  List<AIProvider> getProvidersByCapability(
      bool Function(AIProviderCapabilities caps) selector) {
    return _providers.values
        .where(
            (p) => selector(p.capabilities) && p.state == AIProviderState.ready)
        .toList();
  }

  AIProvider? selectBestProvider(
      bool Function(AIProviderCapabilities caps) selector) {
    final candidates = getProvidersByCapability(selector);
    if (candidates.isEmpty) return null;
    candidates.sort((a, b) => b.priority.compareTo(a.priority));
    return candidates.first;
  }

  void clear() {
    _providers.clear();
  }
}
