import 'workflow_node.dart';
import 'workflow_edge.dart';

class WorkflowDefinition {
  final List<WorkflowNode> nodes;
  final List<WorkflowEdge> edges;

  const WorkflowDefinition({required this.nodes, required this.edges});
}
