import 'package:test/test.dart';
import 'package:indiverse_developer_platform/core/agent/scheduler/local_scheduler.dart';
import 'package:indiverse_developer_platform/core/agent/scheduler/execution_plan.dart';
import 'package:indiverse_developer_platform/core/agent/workflow/workflow_definition.dart';

void main() {
  group('TaskScheduler Tests', () {
    test('Schedule local tasks using execution plans', () async {
      final scheduler = LocalScheduler();
      final plan =
          const ExecutionPlan(WorkflowDefinition(nodes: [], edges: []));
      final result = await scheduler.schedule(plan);
      expect(result.success, isTrue);
    });
  });
}
