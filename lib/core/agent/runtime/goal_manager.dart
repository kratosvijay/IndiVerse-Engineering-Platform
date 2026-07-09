import '../workflow/execution_state.dart';

class GoalManager {
  double calculateProgress(ExecutionSession session) {
    final totalSteps = session.graph.steps.length;
    if (totalSteps == 0) return 1.0;

    final finishedCount = session.stepStates.values
        .where((s) =>
            s.status == StepStatus.completed ||
            s.status == StepStatus.failed ||
            s.status == StepStatus.skipped)
        .length;

    return finishedCount / totalSteps;
  }

  bool isGoalCompleted(ExecutionSession session) {
    if (session.graph.steps.isEmpty) return true;
    return session.stepStates.values.every((s) =>
        s.status == StepStatus.completed ||
        s.status == StepStatus.failed ||
        s.status == StepStatus.skipped);
  }
}
