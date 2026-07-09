import '../workflow/execution_state.dart';
import '../workflow/task_step.dart';
import '../../workspace/graph/workspace_snapshot.dart';

class ReflectionContext {
  final String goal;
  final ExecutionSession session;
  final TaskStep activeStep;
  final StepExecutionState stepState;
  final String? lastFailure;
  final Map<String, dynamic> diagnostics;
  final WorkspaceSnapshot? workspaceSnapshot;

  const ReflectionContext({
    required this.goal,
    required this.session,
    required this.activeStep,
    required this.stepState,
    this.lastFailure,
    this.diagnostics = const {},
    this.workspaceSnapshot,
  });
}
