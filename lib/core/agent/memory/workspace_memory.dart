import '../contracts/memory_provider.dart';

class WorkspaceMemory implements MemoryProvider {
  final Map<String, String> _data = {};

  @override
  Future<void> save(String key, String value) async => _data[key] = value;
  @override
  Future<String?> retrieve(String key) async => _data[key];
  @override
  Future<void> clear() async => _data.clear();
}
