import '../../workflow/task_graph.dart';
import '../../../workspace/graph/workspace_snapshot.dart';

class ExecutionConstraint {
  final String key;
  final String value;

  const ExecutionConstraint({
    required this.key,
    required this.value,
  });
}

class ExecutionPlan {
  final String planId;
  final TaskGraph graph;
  final List<ExecutionConstraint> constraints;
  final WorkspaceSnapshot snapshot;

  const ExecutionPlan({
    required this.planId,
    required this.graph,
    required this.constraints,
    required this.snapshot,
  });
}
