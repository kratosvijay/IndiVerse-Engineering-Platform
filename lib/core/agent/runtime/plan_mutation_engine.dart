import '../workflow/task_graph.dart';
import '../workflow/task_step.dart';

class PlanMutationEngine {
  /// Inserts [newSteps] sequentially after [afterStepId].
  /// Updates existing steps that depend on [afterStepId] to depend on the last step of [newSteps].
  TaskGraph insertSteps(
      TaskGraph graph, String afterStepId, List<TaskStep> newSteps) {
    if (newSteps.isEmpty) return graph;

    final steps = List<TaskStep>.from(graph.steps);
    final index = steps.indexWhere((s) => s.id == afterStepId);
    if (index == -1) return graph;

    // Build the sequential chain for new steps
    final preparedNewSteps = <TaskStep>[];
    for (var i = 0; i < newSteps.length; i++) {
      final step = newSteps[i];
      final deps = i == 0 ? [afterStepId] : [newSteps[i - 1].id];
      preparedNewSteps.add(TaskStep(
        id: step.id,
        title: step.title,
        type: step.type,
        toolId: step.toolId,
        arguments: step.arguments,
        dependencies: deps,
        policy: step.policy,
      ));
    }

    final lastNewStepId = preparedNewSteps.last.id;

    // Update existing steps that depended on afterStepId
    for (var i = 0; i < steps.length; i++) {
      final step = steps[i];
      if (step.dependencies.contains(afterStepId)) {
        final updatedDeps = List<String>.from(step.dependencies)
          ..remove(afterStepId)
          ..add(lastNewStepId);
        steps[i] = TaskStep(
          id: step.id,
          title: step.title,
          type: step.type,
          toolId: step.toolId,
          arguments: step.arguments,
          dependencies: updatedDeps,
          policy: step.policy,
        );
      }
    }

    // Insert preparedNewSteps into steps list
    steps.insertAll(index + 1, preparedNewSteps);

    return TaskGraph(
      id: graph.id,
      goal: graph.goal,
      steps: steps,
    );
  }

  /// Replaces [stepId] with [replacementSteps].
  /// The first replacement step inherits the dependencies of [stepId].
  /// Existing steps depending on [stepId] are updated to depend on the last replacement step.
  TaskGraph replaceStep(
      TaskGraph graph, String stepId, List<TaskStep> replacementSteps) {
    final steps = List<TaskStep>.from(graph.steps);
    final index = steps.indexWhere((s) => s.id == stepId);
    if (index == -1) return graph;

    final targetStep = steps[index];

    if (replacementSteps.isEmpty) {
      // If replacing with empty list, bypass the step
      return bypassStep(graph, stepId);
    }

    // Build the sequential chain for replacement steps
    final preparedReplacements = <TaskStep>[];
    for (var i = 0; i < replacementSteps.length; i++) {
      final step = replacementSteps[i];
      final deps =
          i == 0 ? targetStep.dependencies : [replacementSteps[i - 1].id];
      preparedReplacements.add(TaskStep(
        id: step.id,
        title: step.title,
        type: step.type,
        toolId: step.toolId,
        arguments: step.arguments,
        dependencies: deps,
        policy: step.policy,
      ));
    }

    final lastReplacementId = preparedReplacements.last.id;

    // Remove the target step
    steps.removeAt(index);

    // Update existing steps that depended on targetStepId
    for (var i = 0; i < steps.length; i++) {
      final step = steps[i];
      if (step.dependencies.contains(stepId)) {
        final updatedDeps = List<String>.from(step.dependencies)
          ..remove(stepId)
          ..add(lastReplacementId);
        steps[i] = TaskStep(
          id: step.id,
          title: step.title,
          type: step.type,
          toolId: step.toolId,
          arguments: step.arguments,
          dependencies: updatedDeps,
          policy: step.policy,
        );
      }
    }

    // Insert prepared replacements
    steps.insertAll(index, preparedReplacements);

    return TaskGraph(
      id: graph.id,
      goal: graph.goal,
      steps: steps,
    );
  }

  /// Removes [stepId] and links any steps depending on it to [stepId]'s dependencies instead.
  TaskGraph bypassStep(TaskGraph graph, String stepId) {
    final steps = List<TaskStep>.from(graph.steps);
    final index = steps.indexWhere((s) => s.id == stepId);
    if (index == -1) return graph;

    final targetStep = steps[index];
    steps.removeAt(index);

    for (var i = 0; i < steps.length; i++) {
      final step = steps[i];
      if (step.dependencies.contains(stepId)) {
        final updatedDeps = List<String>.from(step.dependencies)
          ..remove(stepId);
        // Add targetStep's dependencies to avoid breaking DAG continuity
        for (final dep in targetStep.dependencies) {
          if (!updatedDeps.contains(dep)) {
            updatedDeps.add(dep);
          }
        }
        steps[i] = TaskStep(
          id: step.id,
          title: step.title,
          type: step.type,
          toolId: step.toolId,
          arguments: step.arguments,
          dependencies: updatedDeps,
          policy: step.policy,
        );
      }
    }

    return TaskGraph(
      id: graph.id,
      goal: graph.goal,
      steps: steps,
    );
  }
}
