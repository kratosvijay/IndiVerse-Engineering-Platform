import 'graph/relation.dart';

class KnowledgeGraph {
  final List<Relation> _relations = [];

  void addRelation(Relation relation) {
    _relations.add(relation);
  }

  List<Relation> get relations => List.unmodifiable(_relations);

  List<Relation> getOutgoing(String node) {
    return _relations.where((r) => r.from == node).toList();
  }
}
