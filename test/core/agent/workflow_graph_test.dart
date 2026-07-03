import 'package:test/test.dart';
import 'package:indiverse_developer_platform/core/agent/workflow/workflow_definition.dart';
import 'package:indiverse_developer_platform/core/agent/workflow/workflow_node.dart';
import 'package:indiverse_developer_platform/core/agent/workflow/workflow_edge.dart';

void main() {
  group('Workflow Graph Tests', () {
    test('Construct nodes and edges in workflow definition', () {
      const nodeA = WorkflowNode('node-a', 'planner');
      const nodeB = WorkflowNode('node-b', 'developer');
      const edge = WorkflowEdge('node-a', 'node-b');

      final workflow = const WorkflowDefinition(
        nodes: [nodeA, nodeB],
        edges: [edge],
      );

      expect(workflow.nodes.length, equals(2));
      expect(workflow.edges.length, equals(1));
    });
  });
}
