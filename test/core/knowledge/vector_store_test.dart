import 'package:test/test.dart';
import 'package:indiverse_developer_platform/core/knowledge/stores/memory_store.dart';
import 'package:indiverse_developer_platform/core/knowledge/stores/sqlite_store.dart';

void main() {
  group('VectorStore Tests', () {
    test('InMemoryVectorStore insert, search & metadata filters', () async {
      final store = InMemoryVectorStore();
      await store.insert('1', [1.0, 0.0, 0.0], {'lang': 'dart'});
      await store.insert('2', [0.0, 1.0, 0.0], {'lang': 'python'});

      final results = await store.search([1.0, 0.0, 0.0], limit: 1);
      expect(results.length, equals(1));
      expect(results[0].id, equals('1'));

      final metaResults =
          await store.searchByMetadata({'lang': 'python'}, limit: 1);
      expect(metaResults.length, equals(1));
      expect(metaResults[0].id, equals('2'));
    });

    test('SqliteVectorStore mock persists check', () async {
      final store = SqliteVectorStore();
      final stats = await store.stats();
      expect(stats['storeType'], equals('sqlite'));
    });
  });
}
