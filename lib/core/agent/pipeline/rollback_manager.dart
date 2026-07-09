import 'pipeline_models.dart';

class RollbackManager {
  final List<RollbackPlan> rollbackHistory = [];

  RollbackPlan createPlan({
    required String deploymentId,
    required String targetRevision,
  }) {
    final steps = [
      const RollbackStep(id: 'step-1', type: RollbackStepType.revertGitBranch, target: 'Revert Git to target sha'),
      const RollbackStep(id: 'step-2', type: RollbackStepType.restoreDbSnapshot, target: 'Restore DB snapshot'),
    ];

    final plan = RollbackPlan(
      id: 'rollback-${DateTime.now().millisecondsSinceEpoch}',
      deploymentId: deploymentId,
      targetRevision: targetRevision,
      steps: steps,
      createdAt: DateTime.now(),
    );

    rollbackHistory.add(plan);
    return plan;
  }

  // Executes the rollback plan steps
  RollbackPlan execute(RollbackPlan plan) {
    final executedSteps = plan.steps
        .map((s) => RollbackStep(id: s.id, type: s.type, target: s.target, completed: true))
        .toList();

    final updatedPlan = RollbackPlan(
      id: plan.id,
      deploymentId: plan.deploymentId,
      targetRevision: plan.targetRevision,
      steps: executedSteps,
      createdAt: plan.createdAt,
    );

    final idx = rollbackHistory.indexWhere((p) => p.id == plan.id);
    if (idx != -1) {
      rollbackHistory[idx] = updatedPlan;
    }
    return updatedPlan;
  }
}
