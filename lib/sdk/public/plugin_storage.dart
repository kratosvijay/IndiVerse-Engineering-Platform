abstract class PluginStorage {
  Future<void> save(String key, String value);
  Future<String?> read(String key);
  Future<void> delete(String key);
  Future<void> cache(String key, String value, Duration ttl);
}

class MemoryPluginStorage implements PluginStorage {
  final Map<String, String> _data = {};

  @override
  Future<void> save(String key, String value) async => _data[key] = value;

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<void> delete(String key) async => _data.remove(key);

  @override
  Future<void> cache(String key, String value, Duration ttl) async =>
      _data[key] = value;
}
