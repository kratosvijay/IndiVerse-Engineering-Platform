abstract class MemoryProvider {
  Future<void> save(String key, String value);
  Future<String?> retrieve(String key);
  Future<void> clear();
}
