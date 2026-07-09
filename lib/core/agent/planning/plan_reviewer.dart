import '../workflow/task_graph.dart';
import 'planning_models.dart';

class PlanReviewer {
  // Evaluates the execution plan for compliance, cycles, and redundancies
  PlanValidation review(
    GoalAnalysis goalAnalysis,
    Requirement requirement,
    ArchitectureImpact impact,
    TaskGraph graph,
  ) {
    final warnings = <String>[];
    final recommendations = <String>[];
    var valid = true;

    // 1. Cyclic Dependency Check
    if (_hasCycles(graph)) {
      warnings.add('Cyclic dependencies detected in task graph!');
      valid = false;
    }

    // 2. Check for missing tests in impacts
    if (impact.tests.isEmpty) {
      warnings.add('No test files designated for modified modules.');
      recommendations.add('Add integration or unit tests for services.');
    }

    // 3. Clean Architecture layer check (e.g. Services should not directly depend on UI)
    if (impact.services.any((s) => s.contains('view') || s.contains('widget'))) {
      warnings.add('Possible Clean Architecture violation: service matches widget name.');
      recommendations.add('Decouple logic layer elements from widget symbols.');
    }

    // 4. Extensible recommendations
    if (goalAnalysis.type == GoalType.bugfix) {
      recommendations.add('Inspect diagnostics before executing modifications.');
    }

    return PlanValidation(
      valid: valid,
      warnings: warnings,
      recommendations: recommendations,
    );
  }

  bool _hasCycles(TaskGraph graph) {
    final visited = <String, int>{}; // 0 = unvisited, 1 = visiting, 2 = visited
    for (final step in graph.steps) {
      visited[step.id] = 0;
    }

    bool dfs(String stepId) {
      visited[stepId] = 1;

      final step = graph.steps.firstWhere((s) => s.id == stepId);
      for (final depId in step.dependencies) {
        // Safe check if dependency step is present
        final depExists = graph.steps.any((s) => s.id == depId);
        if (!depExists) continue;

        if (visited[depId] == 1) return true; // cycle!
        if (visited[depId] == 0) {
          if (dfs(depId)) return true;
        }
      }

      visited[stepId] = 2;
      return false;
    }

    for (final step in graph.steps) {
      if (visited[step.id] == 0) {
        if (dfs(step.id)) return true;
      }
    }

    return false;
  }
}
