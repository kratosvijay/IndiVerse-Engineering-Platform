import 'secret_provider.dart';

class ApiKeyManager {
  final List<SecretProvider> _providers = [];

  void addProvider(SecretProvider provider) {
    _providers.add(provider);
  }

  Future<String> getApiKey(String serviceName) async {
    for (final provider in _providers) {
      final key = await provider.getSecret(serviceName);
      if (key != null && key.isNotEmpty) {
        return key;
      }
    }
    throw StateError("API key not found for service: $serviceName");
  }
}
