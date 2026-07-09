import 'pipeline_models.dart';
import 'pipeline_provider.dart';
import 'deployment_engine.dart';
import 'deployment_health_monitor.dart';
import 'rollback_manager.dart';

class PipelineOrchestrator {
  final PipelineProvider provider;
  final DeploymentEngine deploymentEngine;
  final DeploymentHealthMonitor healthMonitor;
  final RollbackManager rollbackManager;
  final List<PipelineEvent> events = [];

  PipelineOrchestrator({
    PipelineProvider? provider,
    DeploymentEngine? deploymentEngine,
    DeploymentHealthMonitor? healthMonitor,
    RollbackManager? rollbackManager,
  })  : provider = provider ?? LocalPipelineProvider(),
        deploymentEngine = deploymentEngine ?? const DeploymentEngine(),
        healthMonitor = healthMonitor ?? const DeploymentHealthMonitor(),
        rollbackManager = rollbackManager ?? RollbackManager();

  Future<PipelineRun> triggerPipeline(String commitHash) async {
    final run = await provider.trigger(commitHash);
    events.add(
      PipelineStarted(
        id: 'evt-${DateTime.now().millisecondsSinceEpoch}',
        timestamp: DateTime.now(),
        runId: run.id,
      ),
    );
    return run;
  }

  DeploymentResult runDeployment(
    String deploymentId,
    DeploymentTarget target, {
    bool userApproved = false,
  }) {
    events.add(
      DeploymentStarted(
        id: 'evt-${DateTime.now().millisecondsSinceEpoch}',
        timestamp: DateTime.now(),
        deploymentId: deploymentId,
        target: target,
      ),
    );

    final res = deploymentEngine.deploy(deploymentId, target,
        userApproved: userApproved);

    if (res.status == DeploymentStatus.pendingApproval) {
      events.add(
        ApprovalRequested(
          id: 'evt-${DateTime.now().millisecondsSinceEpoch}',
          timestamp: DateTime.now(),
          approvalId: 'appr-$deploymentId',
          target: target,
        ),
      );
    }

    return res;
  }

  RollbackPlan triggerRollback(String deploymentId, String stableRevision) {
    events.add(
      RollbackStarted(
        id: 'evt-${DateTime.now().millisecondsSinceEpoch}',
        timestamp: DateTime.now(),
        rollbackId: 'roll-$deploymentId',
        targetRevision: stableRevision,
      ),
    );

    final plan = rollbackManager.createPlan(
      deploymentId: deploymentId,
      targetRevision: stableRevision,
    );

    final executed = rollbackManager.execute(plan);

    events.add(
      RollbackCompleted(
        id: 'evt-${DateTime.now().millisecondsSinceEpoch}',
        timestamp: DateTime.now(),
        rollbackId: plan.id,
      ),
    );

    return executed;
  }
}

class PipelineOrchestratorRegistry {
  static PipelineOrchestrator? _active;
  static PipelineOrchestrator? get active => _active;
  static set active(PipelineOrchestrator? orchestrator) =>
      _active = orchestrator;

  static final Map<String, PipelineOrchestrator> _registry = {};
  static void register(String workspaceId, PipelineOrchestrator orchestrator) {
    _registry[workspaceId] = orchestrator;
    _active ??= orchestrator;
  }

  static PipelineOrchestrator? get(String workspaceId) =>
      _registry[workspaceId];
  static void clear() {
    _registry.clear();
    _active = null;
  }
}
