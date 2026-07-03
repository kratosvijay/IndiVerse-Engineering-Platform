import '../contracts/ai_provider.dart';
import 'provider_registry.dart';

class ProviderDiscovery {
  final ProviderRegistry registry;

  ProviderDiscovery(this.registry);

  List<String> get installedProviders => registry.registeredProviders;

  AIProvider? getProvider(String name) {
    try {
      return registry.resolve(name);
    } catch (_) {
      return null;
    }
  }
}
