import 'package:test/test.dart';
import 'package:indiverse_developer_platform/core/agent/distributed/distributed_models.dart';
import 'package:indiverse_developer_platform/core/agent/distributed/agent_cluster.dart';
import 'package:indiverse_developer_platform/core/agent/distributed/cloud_provider.dart';
import 'package:indiverse_developer_platform/core/agent/distributed/distributed_scheduler.dart';
import 'package:indiverse_developer_platform/core/agent/distributed/workspace_lease_manager.dart';
import 'package:indiverse_developer_platform/core/agent/distributed/shared_knowledge_bus.dart';
import 'package:indiverse_developer_platform/core/studio/services/tools/cluster_tools.dart';
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
  group('Sprint 22.7 - Distributed Agent Cloud & Remote Execution Tests', () {
    test('Worker registry registers and heartbeats successfully', () {
      final cluster = AgentCluster(clusterId: 'cluster-beta');
      const capabilities = WorkerCapabilities(
        planning: true,
        generation: true,
        verification: true,
        deployment: true,
        languages: ['dart'],
        tools: ['git'],
        cpuCores: 4,
        ramMb: 8192,
        gpu: false,
      );

      final worker = AgentWorker(
        id: 'worker-1',
        clusterId: 'cluster-beta',
        nodeId: 'node-1',
        state: WorkerState.healthy,
        capabilities: capabilities,
        cpuUsage: 10.0,
        memoryUsage: 30.0,
        runningJobsCount: 0,
        lastHeartbeat: DateTime.now(),
        version: '1.0.0',
      );

      cluster.registerWorker(worker);
      expect(cluster.registry.getWorkers().length, equals(1));
      expect(cluster.registry.getWorkers().first.id, equals('worker-1'));

      // Test stale eviction
      cluster.heartbeatManager.heartbeats['worker-1'] =
          DateTime.now().subtract(const Duration(seconds: 15));
      cluster.evictStaleWorkers();
      expect(cluster.registry.getWorkers(), isEmpty);
    });

    test('DistributedScheduler schedules capability-aware workloads', () {
      const scheduler = DistributedScheduler();
      const capPlanning = WorkerCapabilities(
        planning: true,
        generation: false,
        verification: false,
        deployment: false,
        languages: [],
        tools: [],
        cpuCores: 2,
        ramMb: 4096,
        gpu: false,
      );
      const capGeneration = WorkerCapabilities(
        planning: false,
        generation: true,
        verification: false,
        deployment: false,
        languages: [],
        tools: [],
        cpuCores: 4,
        ramMb: 8192,
        gpu: false,
      );

      final planner = AgentWorker(
        id: 'w-planner',
        clusterId: 'c-1',
        nodeId: 'n-1',
        state: WorkerState.healthy,
        capabilities: capPlanning,
        cpuUsage: 10.0,
        memoryUsage: 20.0,
        runningJobsCount: 0,
        lastHeartbeat: DateTime.now(),
        version: '1.0.0',
      );
      final generator = AgentWorker(
        id: 'w-generator',
        clusterId: 'c-1',
        nodeId: 'n-2',
        state: WorkerState.healthy,
        capabilities: capGeneration,
        cpuUsage: 15.0,
        memoryUsage: 30.0,
        runningJobsCount: 0,
        lastHeartbeat: DateTime.now(),
        version: '1.0.0',
      );

      final jobPlan = ClusterJob(
        id: 'j-1',
        clusterId: 'c-1',
        targetWorkerId: '',
        stageName: 'planning',
        state: ClusterJobState.queued,
        priority: 1,
        arguments: const {},
        createdAt: DateTime.now(),
      );

      final jobGen = ClusterJob(
        id: 'j-2',
        clusterId: 'c-1',
        targetWorkerId: '',
        stageName: 'generation',
        state: ClusterJobState.queued,
        priority: 1,
        arguments: const {},
        createdAt: DateTime.now(),
      );

      final selectedPlan =
          scheduler.selectWorker([planner, generator], jobPlan);
      expect(selectedPlan?.id, equals('w-planner'));

      final selectedGen = scheduler.selectWorker([planner, generator], jobGen);
      expect(selectedGen?.id, equals('w-generator'));
    });

    test('WorkspaceLeaseManager acquires, renews and blocks conflicts', () {
      final manager = WorkspaceLeaseManager();

      final lease = manager.acquireLease(
        type: LeaseType.file,
        resourcePath: 'lib/main.dart',
        ownerAgentId: 'agent-1',
        duration: const Duration(seconds: 5),
      );

      expect(lease, isNotNull);
      expect(lease?.leaseVersion, equals(1));

      // Attempt to acquire conflicting lease
      expect(
        () => manager.acquireLease(
          type: LeaseType.file,
          resourcePath: 'lib/main.dart',
          ownerAgentId: 'agent-2',
          duration: const Duration(seconds: 5),
        ),
        throwsException,
      );

      // Renew lease
      final renewed =
          manager.renewLease(lease!.leaseId, const Duration(seconds: 10));
      expect(renewed?.renewCount, equals(1));
      expect(renewed?.leaseVersion, equals(2));
    });

    test('SharedKnowledgeBus queries federated node document databases', () {
      final bus = SharedKnowledgeBus();
      const doc = FederatedKnowledgeDocument(
        id: 'doc-1',
        title: 'Project architecture guidelines',
        content: 'Clean architecture separation rules details.',
        sourceNodeId: 'node-1',
        tags: {},
      );

      bus.publish('node-1', doc);
      final results = bus.queryFederated('clean architecture');
      expect(results.length, equals(1));
      expect(results.first.id, equals('doc-1'));
    });

    test('Cloud providers inspect environments', () async {
      final cp = DockerCloudProvider();
      final stats = await cp.inspect('docker-1');
      expect(stats['image'], equals('indiverse-agent-worker:latest'));
    });

    test('Cluster Tools execute via ToolExecutionService successfully',
        () async {
      final registry = TestToolRegistry();
      registry.register(ClusterStatusTool());
      registry.register(ClusterWorkersTool());
      registry.register(ClusterSubmitTool());
      registry.register(ClusterCancelTool());
      registry.register(ClusterLogsTool());
      registry.register(ClusterHealthTool());
      registry.register(ClusterMetricsTool());
      registry.register(ClusterRegisterTool());
      registry.register(ClusterUnregisterTool());
      registry.register(ClusterLeasesTool());
      registry.register(ClusterScaleTool());

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
        conversationId: 'conv-cluster',
        requestId: 'req-cluster',
        providerId: 'prov-1',
        modelId: 'mod-1',
        cancellationToken: CancellationToken(),
        sdk: sdk,
      );

      final requestStatus = const ToolCallRequest(
        toolCallId: 'call-status',
        toolName: 'cluster.status',
        arguments: {},
      );

      final resStatus = await service.execute(requestStatus, context);
      expect(resStatus.success, isTrue);

      final requestSubmit = const ToolCallRequest(
        toolCallId: 'call-submit',
        toolName: 'cluster.submit',
        arguments: {'stageName': 'planning'},
      );

      final resSubmit = await service.execute(requestSubmit, context);
      expect(resSubmit.success, isTrue);
    });
  });
}
