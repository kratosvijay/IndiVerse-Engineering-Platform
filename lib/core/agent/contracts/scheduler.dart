import '../scheduler/execution_plan.dart';
import '../workflow/workflow_result.dart';

abstract class Scheduler {
  Future<WorkflowResult> schedule(ExecutionPlan plan);
}
