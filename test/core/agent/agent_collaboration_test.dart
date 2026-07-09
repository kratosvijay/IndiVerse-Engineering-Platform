import 'dart:async';
import 'package:test/test.dart';
import 'package:indiverse_developer_platform/core/agent/runtime/agent_runtime.dart';
import 'package:indiverse_developer_platform/core/agent/runtime/agent_runtime_event.dart';
import 'package:indiverse_developer_platform/core/agent/runtime/reflection_engine.dart';
import 'package:indiverse_developer_platform/core/agent/runtime/plan_mutation_engine.dart';
import 'package:indiverse_developer_platform/core/agent/runtime/goal_manager.dart';
import 'package:indiverse_developer_platform/core/agent/workflow/plan_executor.dart';
import 'package:indiverse_developer_platform/core/agent/workflow/step_executor.dart';
import 'package:indiverse_developer_platform/core/agent/workflow/task_graph.dart';
import 'package:indiverse_developer_platform/core/agent/workflow/task_step.dart';
import 'package:indiverse_developer_platform/core/studio/services/tool_execution_service.dart';
import 'package:indiverse_developer_platform/core/studio/services/tool_registry.dart';
import 'package:indiverse_developer_platform/core/studio/services/permission_store.dart';
import 'package:indiverse_developer_platform/core/models/tool_call_models.dart';
import 'package:indiverse_developer_platform/core/prompt/prompt_pipeline.dart';
import 'package:indiverse_developer_platform/core/workspace/graph/workspace_snapshot.dart';
import 'package:indiverse_developer_platform/core/workspace/index/build_intelligence.dart';
import 'package:indiverse_developer_platform/core/agent/runtime/multi_agent/agent_role.dart';
import 'package:indiverse_developer_platform/core/agent/runtime/multi_agent/agent_envelope.dart';
import 'package:indiverse_developer_platform/core/agent/runtime/multi_agent/agent_memory.dart';
import 'package:indiverse_developer_platform/core/agent/runtime/multi_agent/agent_registry.dart';
import 'package:indiverse_developer_platform/core/agent/runtime/multi_agent/agent_message_bus.dart';
import 'package:indiverse_developer_platform/core/agent/runtime/multi_agent/agent_scheduler.dart';
import 'package:indiverse_developer_platform/core/agent/runtime/multi_agent/conflict_resolver.dart';
import 'package:indiverse_developer_platform/core/agent/runtime/multi_agent/coordinator_agent.dart';
import 'package:indiverse_developer_platform/core/agent/runtime/multi_agent/execution_plan.dart';
import 'package:indiverse_developer_platform/platform_sdk/platform_sdk.dart';
import 'package:indiverse_developer_platform/platform_sdk/runtime_api.dart';
import 'package:indiverse_developer_platform/platform_sdk/workspace_api.dart';
import 'package:indiverse_developer_platform/platform_sdk/knowledge_api.dart';
import 'package:indiverse_developer_platform/platform_sdk/agent_api.dart';
import 'package:indiverse_developer_platform/platform_sdk/plugin_api.dart';

class TestToolRegistry extends ToolRegistry {}

class TestPermissionStore extends ToolPermissionStore {
  @override
  PermissionDecision? getDecision(String toolName) => null;
}

void main() {
  group('Sprint 21.9 - Multi-Agent Collaboration Tests', () {
    late AgentRuntime dummyRuntime;
    late WorkspaceSnapshot testSnapshot;

    setUp(() {
      final reflection = ReflectionEngine();
      final mutation = PlanMutationEngine();
      final goalMan = GoalManager();
      final toolService = ToolExecutionService(
        registry: TestToolRegistry(),
        permissionStore: TestPermissionStore(),
      );
      final sdk = PlatformSDK(
        runtime: RuntimeAPI(),
        workspace: WorkspaceAPI(),
        knowledge: KnowledgeAPI(),
        agent: AgentAPI(),
        plugin: PluginAPI(),
      );
      final stepExec = StepExecutor(toolService, sdk);
      final executor = PlanExecutor(
        stepExec,
        reflectionEngine: reflection,
        mutationEngine: mutation,
      );

      dummyRuntime = AgentRuntime(
        planExecutor: executor,
        goalManager: goalMan,
        reflectionEngine: reflection,
      );

      testSnapshot = WorkspaceSnapshot(
        snapshotId: 'snap-1',
        version: 1,
        createdAt: DateTime.now(),
        workspaceHash: 'hash-1',
        symbols: const [],
        dependencies: const [],
        calls: const [],
        buildDiagnostics: const [],
        classes: const [],
        enums: const [],
        mixins: const [],
        typedefs: const [],
        extensions: const [],
        routes: const [],
        services: const [],
        providers: const [],
      );
    });

    test('AgentRegistry matches agents by roles and capabilities', () {
      final registry = AgentRegistry();

      final planners = registry.getAgentsByRole(AgentRole.planner);
      expect(planners, isNotEmpty);
      expect(planners.first.descriptor.role, equals(AgentRole.planner));

      final coders = registry.getAgentsByCapability(AgentCapability.coding);
      expect(coders, isNotEmpty);
      expect(coders.first.descriptor.capabilities,
          contains(AgentCapability.coding));
    });

    test('AgentMessageBus broadcasts and filters typed envelope messages',
        () async {
      final bus = AgentMessageBus();
      final envelope = AgentEnvelope<String>(
        envelopeId: 'env-1',
        senderId: 'agent.planner',
        recipientId: 'agent.coder',
        timestamp: DateTime.now(),
        payload: 'Create class AuthController',
      );

      final events = <AgentEnvelope<String>>[];
      final sub = bus.filterByType<String>().listen(events.add);

      bus.publish(envelope);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(events, hasLength(1));
      expect(events.first.payload, equals('Create class AuthController'));
      await sub.cancel();
    });

    test(
        'SharedMemory segments separate artifacts, reasoning, facts, and diagnostics',
        () {
      final memory = SharedMemory();

      memory.artifacts.publish('art-1', 'print("Hello");');
      memory.reasoning.record('agent.coder', 'Writing standard boilerplate.');
      memory.facts.addFact('Project uses Clean Architecture standard.');
      memory.diagnostics.add(const BuildDiagnostic(
        origin: DiagnosticOrigin.compiler,
        filePath: 'lib/main.dart',
        line: 10,
        column: 2,
        message: 'Syntax error',
        severity: DiagnosticSeverity.error,
      ));

      expect(memory.artifacts.get('art-1'), equals('print("Hello");'));
      expect(memory.reasoning.getForAgent('agent.coder'),
          contains('Writing standard boilerplate.'));
      expect(memory.facts.all,
          contains('Project uses Clean Architecture standard.'));
      expect(memory.diagnostics.all.first.message, equals('Syntax error'));
    });

    test('AgentScheduler topologically resolves dependent execution graphs',
        () {
      final scheduler = AgentScheduler();

      final stepA = const TaskStep(id: 'A', title: 'Prepare');
      final stepB = const TaskStep(id: 'B', title: 'Code', dependencies: ['A']);
      final stepC =
          const TaskStep(id: 'C', title: 'Review', dependencies: ['B']);

      final graph = TaskGraph(
        id: 'graph-1',
        goal: 'test task graph',
        steps: [stepC, stepB, stepA],
      );
      final plan = ExecutionPlan(
        planId: 'plan-1',
        graph: graph,
        constraints: const [],
        snapshot: testSnapshot,
      );

      final order = scheduler.resolveExecutionOrder(plan);
      expect(order, hasLength(3));
      expect(order[0].id, equals('A'));
      expect(order[1].id, equals('B'));
      expect(order[2].id, equals('C'));
    });

    test('ConflictResolver yields resolution strategies for overlapping writes',
        () {
      final resolver = ConflictResolver();

      // Case 1: No overlap
      final resolution1 = resolver.detectAndResolve([
        AgentFileEdit(
          agentId: 'agent.coder',
          filePath: 'lib/a.dart',
          content: 'class A {}',
          timestamp: DateTime.now(),
        ),
      ]);
      expect(resolution1, equals(ConflictResolution.merged));

      // Case 2: Overlapping edits of identical content
      final now = DateTime.now();
      final resolution2 = resolver.detectAndResolve([
        AgentFileEdit(
          agentId: 'agent.coder',
          filePath: 'lib/a.dart',
          content: 'class A {}',
          timestamp: now,
        ),
        AgentFileEdit(
          agentId: 'agent.refactorer',
          filePath: 'lib/a.dart',
          content: 'class A {}',
          timestamp: now,
        ),
      ]);
      expect(resolution2, equals(ConflictResolution.merged));

      // Case 3: Overlapping edits of differing content (recent timestamp window -> retry)
      final resolution3 = resolver.detectAndResolve([
        AgentFileEdit(
          agentId: 'agent.coder',
          filePath: 'lib/a.dart',
          content: 'class A { int x = 0; }',
          timestamp: now,
        ),
        AgentFileEdit(
          agentId: 'agent.refactorer',
          filePath: 'lib/a.dart',
          content: 'class A { int y = 1; }',
          timestamp: now.add(const Duration(seconds: 2)),
        ),
      ]);
      expect(resolution3, equals(ConflictResolution.retry));
    });

    test(
        'CoordinatorAgent executes end-to-end multi-agent loop with progress event broadcasts',
        () async {
      final coordinator = CoordinatorAgent(
        executionId: 'exec-collab',
        goalId: 'goal-collab',
      );

      final events = <AgentRuntimeEvent>[];
      final sub = coordinator.events.listen(events.add);

      final token = CancellationToken();
      final success = await coordinator.runCollaboration(
        'Implement clean architecture route validation',
        testSnapshot,
        dummyRuntime,
        token,
      );

      expect(success, isTrue);

      // Verify progress events mapped
      final registered = events.whereType<AgentRegisteredEvent>();
      final spawned = events.whereType<AgentSpawnedEvent>();
      final assigned = events.whereType<TaskAssignedEvent>();
      final completed = events.whereType<TaskCompletedEvent>();
      final finished = events.whereType<CoordinatorFinishedEvent>();

      expect(registered, isNotEmpty);
      expect(spawned, isNotEmpty);
      expect(assigned, isNotEmpty);
      expect(completed, isNotEmpty);
      expect(finished, isNotEmpty);
      expect(finished.first.success, isTrue);

      await sub.cancel();
      coordinator.dispose();
    });
  });
}
