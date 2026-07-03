abstract class SecretProvider {
  Future<String?> getSecret(String key);
}

class EnvironmentSecretProvider implements SecretProvider {
  final Map<String, String> _env;
  EnvironmentSecretProvider([this._env = const {}]);

  @override
  Future<String?> getSecret(String key) async {
    return _env.containsKey(key) ? _env[key] : null;
  }
}
