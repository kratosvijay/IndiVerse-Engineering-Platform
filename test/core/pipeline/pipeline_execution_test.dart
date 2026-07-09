import 'package:test/test.dart';
import 'package:indiverse_developer_platform/core/agent/pipeline/pipeline_models.dart';
import 'package:indiverse_developer_platform/core/agent/pipeline/deployment_policy.dart';
import 'package:indiverse_developer_platform/core/agent/pipeline/deployment_health_monitor.dart';
import 'package:indiverse_developer_platform/core/agent/pipeline/rollback_manager.dart';
import 'package:indiverse_developer_platform/core/agent/pipeline/pipeline_orchestrator.dart';
import 'package:indiverse_developer_platform/core/studio/services/tools/pipeline_tools.dart';
import 'package:indiverse_developer_platform/core/models/tool_call_models.dart';
import 'package:indiverse_developer_platform/core/studio/services/tool_handler.dart';
import 'package:indiverse_developer_platform/core/studio/services/tool_registry.dart';
import 'package:indiverse_developer_platform/core/studio/services/permission_store.dart';
import 'package:indiverse_developer_platform/core/studio/services/tool_execution_service.dart';
import 'package:indiverse_developer_platform/platform_sdk/platform_sdk.dart';
import 'package:indiverse_developer_platform/platform_sdk/runtime_api.dart';
import 'package:indiverse_developer_platform/platform_sdk/workspace_api.dart';
import 'package:indiverse_developer_platform/platform_sdk/knowledge_api.dart';
import 'package:indiverse_developer_platform/platform_sdk/agent_api.dart';
import 'package:indiverse_developer_platform/platform_sdk/plugin_api.dart';
import 'package:indiverse_developer_platform/core/prompt/prompt_pipeline.dart';

class TestToolRegistry extends ToolRegistry {}

class TestPermissionStore extends ToolPermissionStore {
  @override
  PermissionDecision? getDecision(String toolName) => null;
}

void main() {
  group('Sprint 22.6 - CI/CD & Deployment Intelligence Tests', () {
    setUp(() {
      PipelineOrchestratorRegistry.clear();
    });

    test('PipelineRun parses and holds active stages correctly', () {
      final run = PipelineRun(
        id: 'run-1',
        pipelineId: 'pipe-1',
        commitHash: 'sha-1',
        stages: const [
          PipelineStage(
              id: 's-1',
              name: 'Lint',
              status: PipelineStageStatus.passed,
              duration: Duration(seconds: 1)),
        ],
        createdAt: DateTime.now(),
        status: PipelineStageStatus.passed,
      );

      expect(run.id, equals('run-1'));
      expect(run.stages.first.name, equals('Lint'));
      expect(run.status, equals(PipelineStageStatus.passed));
    });

    test(
        'DeploymentPolicy prevents production deployment without user approval',
        () {
      const policy = ProductionApprovalPolicy();

      expect(policy.evaluate(DeploymentTarget.staging, userApproved: false),
          isTrue);
      expect(policy.evaluate(DeploymentTarget.production, userApproved: false),
          isFalse);
      expect(policy.evaluate(DeploymentTarget.production, userApproved: true),
          isTrue);
    });

    test('DeploymentHealthMonitor records metrics and derives health score',
        () {
      const monitor = DeploymentHealthMonitor();

      final healthy = monitor.recordMetrics(
        availability: 1.0,
        crashRate: 0.0,
        errorRate: 0.0,
        responseTimeMs: 120.0,
        resourceUsage: 30.0,
      );
      expect(healthy.healthScore, equals(10.0));

      final unhealthy = monitor.recordMetrics(
        availability: 0.9,
        crashRate: 2.0,
        errorRate: 3.0,
        responseTimeMs: 600.0,
        resourceUsage: 80.0,
      );
      expect(unhealthy.healthScore, lessThan(7.0));
    });

    test(
        'RollbackManager creates rollback plans and completes restoration steps',
        () {
      final manager = RollbackManager();
      final plan = manager.createPlan(
          deploymentId: 'dep-1', targetRevision: 'sha-stable');

      expect(plan.deploymentId, equals('dep-1'));
      expect(plan.steps.first.completed, isFalse);

      final executed = manager.execute(plan);
      expect(executed.steps.first.completed, isTrue);
    });

    test('PipelineOrchestrator coordinates providers and registers events',
        () async {
      final orch = PipelineOrchestrator();
      final run = await orch.triggerPipeline('sha-latest');

      expect(run.pipelineId, equals('pipe-main'));
      expect(orch.events.length, equals(1));
      expect(orch.events.first, isA<PipelineStarted>());

      final depRes = orch.runDeployment('dep-1', DeploymentTarget.production,
          userApproved: false);
      expect(depRes.status, equals(DeploymentStatus.pendingApproval));
      expect(orch.events.any((e) => e is ApprovalRequested), isTrue);
    });

    test('Pipeline Tools execute via ToolExecutionService successfully',
        () async {
      final registry = TestToolRegistry();
      registry.register(PipelineTriggerTool());
      registry.register(PipelineStatusTool());
      registry.register(PipelineLogsTool());
      registry.register(PipelineArtifactsTool());
      registry.register(PipelineCancelTool());
      registry.register(PipelineDeployTool());
      registry.register(PipelineRollbackTool());
      registry.register(PipelineSummaryTool());

      final service = ToolExecutionService(
        registry: registry,
        permissionStore: TestPermissionStore(),
      );

      final sdk = PlatformSDK(
        runtime: RuntimeAPI(),
        workspace: WorkspaceAPI(),
        knowledge: KnowledgeAPI(),
        agent: AgentAPI(),
        plugin: PluginAPI(),
      );

      final context = ToolExecutionContext(
        workspaceId: 'test-ws',
        conversationId: 'conv-pipe',
        requestId: 'req-pipe',
        providerId: 'prov-1',
        modelId: 'mod-1',
        cancellationToken: CancellationToken(),
        sdk: sdk,
      );

      final requestTrigger = const ToolCallRequest(
        toolCallId: 'call-trigger',
        toolName: 'pipeline.trigger',
        arguments: {'commitHash': 'sha-123'},
      );

      final resTrigger = await service.execute(requestTrigger, context);
      expect(resTrigger.success, isTrue);

      final requestDeploy = const ToolCallRequest(
        toolCallId: 'call-deploy',
        toolName: 'pipeline.deploy',
        arguments: {
          'deploymentId': 'dep-789',
          'target': 'production',
          'userApproved': true,
        },
      );

      final resDeploy = await service.execute(requestDeploy, context);
      expect(resDeploy.success, isTrue);
    });
  });
}
