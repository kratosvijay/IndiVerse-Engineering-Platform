import 'package:test/test.dart';
import 'package:indiverse_developer_platform/core/context/context_source.dart';
import 'package:indiverse_developer_platform/core/context/context_manager.dart';

void main() {
  group('ContextManager Tests', () {
    test('should aggregate context sources correctly', () async {
      final manager = ContextManager();
      manager.addSource(StaticContextSource("Global rules"));
      manager.addSource(StaticContextSource("Flutter guidelines"));

      final result = await manager.assembleContext();
      expect(result, contains("Global rules"));
      expect(result, contains("Flutter guidelines"));
    });

    test('should allow clearing and removing sources', () {
      final manager = ContextManager();
      final source = StaticContextSource("Temp");
      manager.addSource(source);
      expect(manager.sources.length, 1);

      manager.removeSource(source);
      expect(manager.sources.length, 0);
    });
  });
}
