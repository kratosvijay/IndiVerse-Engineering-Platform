import 'task_step.dart';
import 'execution_state.dart';

class ReadyStepScheduler {
  List<TaskStep> getReadySteps(ExecutionSession session) {
    final ready = <TaskStep>[];
    for (final step in session.graph.steps) {
      final state = session.stepStates[step.id]!;
      if (state.status == StepStatus.pending) {
        final dependenciesSatisfied = step.dependencies.every((depId) {
          final depState = session.stepStates[depId]!;
          return depState.status == StepStatus.completed ||
              (depState.status == StepStatus.failed &&
                  session.graph.steps
                      .firstWhere((s) => s.id == depId)
                      .policy
                      .continueOnFailure);
        });

        final hasFailedDependencies = step.dependencies.any((depId) {
          final depState = session.stepStates[depId]!;
          return depState.status == StepStatus.failed &&
              !session.graph.steps
                  .firstWhere((s) => s.id == depId)
                  .policy
                  .continueOnFailure;
        });

        if (dependenciesSatisfied && !hasFailedDependencies) {
          ready.add(step);
        }
      }
    }
    return ready;
  }

  List<TaskStep> getBlockedSteps(ExecutionSession session) {
    final blocked = <TaskStep>[];
    for (final step in session.graph.steps) {
      final state = session.stepStates[step.id]!;
      if (state.status == StepStatus.pending) {
        final hasFailedDependencies = step.dependencies.any((depId) {
          final depState = session.stepStates[depId]!;
          return depState.status == StepStatus.failed &&
              !session.graph.steps
                  .firstWhere((s) => s.id == depId)
                  .policy
                  .continueOnFailure;
        });
        if (hasFailedDependencies) {
          blocked.add(step);
        }
      }
    }
    return blocked;
  }
}
