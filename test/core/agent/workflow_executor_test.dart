import 'package:test/test.dart';
import 'package:indiverse_developer_platform/core/agent/workflow/workflow_executor.dart';
import 'package:indiverse_developer_platform/core/agent/workflow/workflow_definition.dart';

void main() {
  group('WorkflowExecutor Tests', () {
    test('Execute workflow definitions', () async {
      final executor = WorkflowExecutor();
      final result = await executor
          .execute(const WorkflowDefinition(nodes: [], edges: []));
      expect(result.success, isTrue);
    });
  });
}
