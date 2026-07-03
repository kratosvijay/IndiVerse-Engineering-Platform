import 'package:test/test.dart';
import 'package:indiverse_developer_platform/core/knowledge/cache/embedding_cache.dart';

void main() {
  group('EmbeddingCache Tests', () {
    test('Save and lookup vectors by checksum', () {
      final cache = EmbeddingCache();
      cache.save('hash1', [1.0, 2.0]);
      expect(cache.get('hash1'), equals([1.0, 2.0]));
      expect(cache.get('nonexistent'), isNull);
    });
  });
}
