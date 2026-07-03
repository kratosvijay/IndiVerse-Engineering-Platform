import '../workflow/workflow_result.dart';

abstract class Workflow {
  String get id;
  String get name;
  Future<WorkflowResult> execute();
}
