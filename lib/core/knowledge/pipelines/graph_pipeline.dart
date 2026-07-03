import '../knowledge_graph.dart';
import '../graph/relation.dart';
import '../graph/relation_type.dart';

class GraphPipeline {
  final KnowledgeGraph graph;

  GraphPipeline({required this.graph});

  Future<void> buildRelations(
      String fromNode, String toNode, RelationType type) async {
    graph.addRelation(Relation(from: fromNode, to: toNode, type: type));
  }
}
