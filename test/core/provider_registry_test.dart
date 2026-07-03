import 'package:test/test.dart';
import 'package:indiverse_developer_platform/core/runtime/provider_registry.dart';
import 'package:indiverse_developer_platform/core/providers/mock_provider.dart';

void main() {
  group('ProviderRegistry Tests', () {
    test('should allow registering and resolving providers', () {
      final registry = ProviderRegistry();
      final mock = MockProvider();

      registry.registerProvider("test-model", mock);
      final resolved = registry.resolve("test-model");

      expect(resolved.name, mock.name);
    });

    test('should throw StateError for missing models', () {
      final registry = ProviderRegistry();
      expect(() => registry.resolve("missing-model"), throwsStateError);
    });
  });
}
