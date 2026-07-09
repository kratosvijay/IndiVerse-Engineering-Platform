import 'dart:async';
import '../../workflow/task_step.dart';
import '../../workflow/ready_step_scheduler.dart';
import '../../workflow/execution_state.dart';
import '../../workflow/task_graph.dart';
import 'execution_plan.dart';

class AgentScheduler {
  final ReadyStepScheduler _readyScheduler = ReadyStepScheduler();

  // Resolves the topological dependency-aware order of execution for a graph plan
  List<TaskStep> resolveExecutionOrder(ExecutionPlan plan) {
    final ordered = <TaskStep>[];
    final visited = <String>{};
    final graph = plan.graph;

    void visit(TaskStep step) {
      if (visited.contains(step.id)) return;
      
      // Visit dependencies first
      for (final depId in step.dependencies) {
        final depStep = graph.steps.firstWhere((s) => s.id == depId);
        visit(depStep);
      }

      visited.add(step.id);
      ordered.add(step);
    }

    for (final step in graph.steps) {
      visit(step);
    }

    return ordered;
  }

  // Returns ready steps that have all their dependencies completed
  List<TaskStep> getReadySteps(ExecutionSession session) {
    return _readyScheduler.getReadySteps(session);
  }
}
