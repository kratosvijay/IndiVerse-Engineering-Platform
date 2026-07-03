import 'api_key_manager.dart';

class CredentialManager {
  final ApiKeyManager apiKeyManager;

  CredentialManager({ApiKeyManager? apiKeyManager})
      : apiKeyManager = apiKeyManager ?? ApiKeyManager();

  Future<String> resolveCredentials(String providerName) async {
    final keyName = "${providerName.toUpperCase()}_API_KEY";
    return await apiKeyManager.getApiKey(keyName);
  }
}
