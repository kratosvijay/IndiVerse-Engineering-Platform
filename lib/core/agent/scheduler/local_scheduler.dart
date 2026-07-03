import '../contracts/scheduler.dart';
import 'execution_plan.dart';
import '../workflow/workflow_result.dart';

class LocalScheduler implements Scheduler {
  @override
  Future<WorkflowResult> schedule(ExecutionPlan plan) async {
    return const WorkflowResult(true, {});
  }
}
