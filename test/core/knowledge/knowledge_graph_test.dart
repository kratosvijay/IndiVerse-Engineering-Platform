import 'package:test/test.dart';
import 'package:indiverse_developer_platform/core/knowledge/knowledge_graph.dart';
import 'package:indiverse_developer_platform/core/knowledge/graph/relation.dart';
import 'package:indiverse_developer_platform/core/knowledge/graph/relation_type.dart';

void main() {
  group('KnowledgeGraph Tests', () {
    test('Add and retrieve graph relations', () {
      final graph = KnowledgeGraph();
      graph.addRelation(const Relation(
        from: 'A',
        to: 'B',
        type: RelationType.imports,
      ));

      final outgoing = graph.getOutgoing('A');
      expect(outgoing.length, equals(1));
      expect(outgoing[0].to, equals('B'));
    });
  });
}
