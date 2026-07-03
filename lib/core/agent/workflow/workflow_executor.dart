import 'workflow_definition.dart';
import 'workflow_result.dart';

class WorkflowExecutor {
  Future<WorkflowResult> execute(WorkflowDefinition def) async {
    return const WorkflowResult(true, {});
  }
}
