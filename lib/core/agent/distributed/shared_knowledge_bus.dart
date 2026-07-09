import 'distributed_models.dart';

class SharedKnowledgeBus {
  final Map<String, List<FederatedKnowledgeDocument>> clusterDocuments = {};

  void publish(String nodeId, FederatedKnowledgeDocument doc) {
    final list = clusterDocuments[nodeId] ?? [];
    list.add(doc);
    clusterDocuments[nodeId] = list;
  }

  // Gateway searches across all nodes to retrieve matches
  List<FederatedKnowledgeDocument> queryFederated(String query) {
    final results = <FederatedKnowledgeDocument>[];
    final cleanQuery = query.toLowerCase().trim();

    for (final entry in clusterDocuments.entries) {
      for (final doc in entry.value) {
        if (doc.title.toLowerCase().contains(cleanQuery) ||
            doc.content.toLowerCase().contains(cleanQuery)) {
          results.add(doc);
        }
      }
    }

    return results;
  }
}
