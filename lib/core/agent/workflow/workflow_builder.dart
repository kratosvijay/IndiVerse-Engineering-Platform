import 'workflow_definition.dart';
import 'workflow_node.dart';
import 'workflow_edge.dart';

class WorkflowBuilder {
  final List<WorkflowNode> _nodes = [];
  final List<WorkflowEdge> _edges = [];

  void addNode(WorkflowNode node) => _nodes.add(node);
  void addEdge(WorkflowEdge edge) => _edges.add(edge);

  WorkflowDefinition build() =>
      WorkflowDefinition(nodes: _nodes, edges: _edges);
}
