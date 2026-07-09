import 'dart:async';
import 'package:test/test.dart';
import 'package:indiverse_developer_platform/core/agent/workflow/agent_planner.dart';
import 'package:indiverse_developer_platform/core/agent/workflow/planner_context.dart';
import 'package:indiverse_developer_platform/core/agent/workflow/task_graph.dart';
import 'package:indiverse_developer_platform/core/agent/workflow/task_step.dart';
import 'package:indiverse_developer_platform/core/agent/workflow/execution_state.dart';
import 'package:indiverse_developer_platform/core/agent/workflow/ready_step_scheduler.dart';
import 'package:indiverse_developer_platform/core/agent/workflow/step_executor.dart';
import 'package:indiverse_developer_platform/core/agent/workflow/plan_executor.dart';
import 'package:indiverse_developer_platform/core/agent/workflow/plan_event.dart';
import 'package:indiverse_developer_platform/core/studio/services/tool_execution_service.dart';
import 'package:indiverse_developer_platform/core/studio/services/tool_registry.dart';
import 'package:indiverse_developer_platform/core/studio/services/permission_store.dart';
import 'package:indiverse_developer_platform/core/models/tool_call_models.dart';
import 'package:indiverse_developer_platform/core/prompt/prompt_pipeline.dart';
import 'package:indiverse_developer_platform/platform_sdk/platform_sdk.dart';
import 'package:indiverse_developer_platform/platform_sdk/runtime_api.dart';
import 'package:indiverse_developer_platform/platform_sdk/workspace_api.dart';
import 'package:indiverse_developer_platform/platform_sdk/knowledge_api.dart';
import 'package:indiverse_developer_platform/platform_sdk/agent_api.dart';
import 'package:indiverse_developer_platform/platform_sdk/plugin_api.dart';

class MockToolRegistry extends ToolRegistry {}

class MockPermissionStore extends ToolPermissionStore {
  final Map<String, PermissionDecision> _decisions = {};

  @override
  PermissionDecision? getDecision(String toolName) => _decisions[toolName];

  void setDecision(String toolName, PermissionDecision decision) {
    _decisions[toolName] = decision;
  }
}

class FakeToolStepExecutor implements StepTypeExecutor {
  bool shouldSucceed = true;
  String errorCode = '';
  String outputText = 'Fake Output';

  @override
  Future<ToolCallResult> execute(
    TaskStep step,
    String workspaceId,
    String conversationId,
    String requestId,
    CancellationToken token,
  ) async {
    if (errorCode == 'PERMISSION_REQUIRED') {
      return const ToolCallResult(
        success: false,
        output: ToolOutput(
            displayText: 'Permission required', mimeType: 'text/plain'),
        duration: Duration.zero,
        errorCode: 'PERMISSION_REQUIRED',
      );
    }
    return ToolCallResult(
      success: shouldSucceed,
      output: ToolOutput(
          displayText: shouldSucceed ? outputText : 'Error details',
          mimeType: 'text/plain'),
      duration: Duration.zero,
      errorCode: shouldSucceed ? null : 'ERROR_CODE',
    );
  }
}

void main() {
  group('Sprint 21.6 - Agent Planning & Task Execution Tests', () {
    late AgentPlanner planner;
    late ReadyStepScheduler scheduler;
    late StepExecutor stepExecutor;
    late PlanExecutor executor;
    late FakeToolStepExecutor fakeToolStepExecutor;

    setUp(() {
      planner = AgentPlanner();
      scheduler = ReadyStepScheduler();

      final mockRegistry = MockToolRegistry();
      final mockPermissionStore = MockPermissionStore();
      final toolExecutionService = ToolExecutionService(
        registry: mockRegistry,
        permissionStore: mockPermissionStore,
      );

      final sdk = PlatformSDK(
        runtime: RuntimeAPI(),
        workspace: WorkspaceAPI(),
        knowledge: KnowledgeAPI(),
        agent: AgentAPI(),
        plugin: PluginAPI(),
      );

      stepExecutor = StepExecutor(toolExecutionService, sdk);
      fakeToolStepExecutor = FakeToolStepExecutor();
      stepExecutor.registerExecutor(StepType.tool, fakeToolStepExecutor);

      executor = PlanExecutor(stepExecutor);
    });

    test('AgentPlanner matches context goals and returns TaskGraph', () async {
      final context = const PlannerContext(
        goal: 'Fix analyzer errors',
        workspacePath: '/workspace',
        conversationId: 'conv-123',
      );

      final graph = await planner.plan(context);
      expect(graph.goal, equals('Fix analyzer errors'));
      expect(graph.steps, isNotEmpty);
      expect(graph.steps.first.title, contains('analysis'));
    });

    test('ReadyStepScheduler extracts ready steps based on dependencies', () {
      final graph = const TaskGraph(
        id: 'plan-1',
        goal: 'Test plan',
        steps: [
          TaskStep(id: 'step-1', title: 'Step 1'),
          TaskStep(id: 'step-2', title: 'Step 2', dependencies: ['step-1']),
        ],
      );

      final session = ExecutionSession(
        executionId: 'exec-1',
        planId: 'plan-1',
        graph: graph,
        status: PlanStatus.ready,
        stepStates: const {
          'step-1':
              StepExecutionState(stepId: 'step-1', status: StepStatus.pending),
          'step-2':
              StepExecutionState(stepId: 'step-2', status: StepStatus.pending),
        },
        startedAt: DateTime.now(),
      );

      final ready = scheduler.getReadySteps(session);
      expect(ready.length, equals(1));
      expect(ready.first.id, equals('step-1'));

      final sessionInProgress = session.copyWith(
        stepStates: const {
          'step-1': StepExecutionState(
              stepId: 'step-1', status: StepStatus.completed),
          'step-2':
              StepExecutionState(stepId: 'step-2', status: StepStatus.pending),
        },
      );

      final readyNext = scheduler.getReadySteps(sessionInProgress);
      expect(readyNext.length, equals(1));
      expect(readyNext.first.id, equals('step-2'));
    });

    test('PlanExecutor runs steps sequentially to completion', () async {
      final graph = const TaskGraph(
        id: 'plan-2',
        goal: 'Test Run',
        steps: [
          TaskStep(id: 'step-1', title: 'Step 1'),
          TaskStep(id: 'step-2', title: 'Step 2', dependencies: ['step-1']),
        ],
      );

      final session = ExecutionSession(
        executionId: 'exec-2',
        planId: 'plan-2',
        graph: graph,
        status: PlanStatus.ready,
        stepStates: const {
          'step-1':
              StepExecutionState(stepId: 'step-1', status: StepStatus.pending),
          'step-2':
              StepExecutionState(stepId: 'step-2', status: StepStatus.pending),
        },
        startedAt: DateTime.now(),
      );

      final events = <PlanEvent>[];
      final sub = executor.progressEvents.listen(events.add);

      final resultSession =
          await executor.execute(session, 'ws-1', 'conv-1', 'req-1');
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(resultSession.status, equals(PlanStatus.completed));
      expect(resultSession.stepStates['step-1']?.status,
          equals(StepStatus.completed));
      expect(resultSession.stepStates['step-2']?.status,
          equals(StepStatus.completed));
      expect(resultSession.progress, equals(1.0));

      expect(events.any((e) => e is PlanStartedEvent), isTrue);
      expect(events.any((e) => e is PlanCompletedEvent), isTrue);
      expect(events.any((e) => e is StepStartedEvent && e.stepId == 'step-1'),
          isTrue);
      expect(events.any((e) => e is StepCompletedEvent && e.stepId == 'step-1'),
          isTrue);
    });

    test('PlanExecutor handles step failure and pauses plan execution',
        () async {
      fakeToolStepExecutor.shouldSucceed = false;

      final graph = const TaskGraph(
        id: 'plan-3',
        goal: 'Test Fail',
        steps: [
          TaskStep(id: 'step-1', title: 'Step 1'),
          TaskStep(id: 'step-2', title: 'Step 2', dependencies: ['step-1']),
        ],
      );

      final session = ExecutionSession(
        executionId: 'exec-3',
        planId: 'plan-3',
        graph: graph,
        status: PlanStatus.ready,
        stepStates: const {
          'step-1':
              StepExecutionState(stepId: 'step-1', status: StepStatus.pending),
          'step-2':
              StepExecutionState(stepId: 'step-2', status: StepStatus.pending),
        },
        startedAt: DateTime.now(),
      );

      final resultSession =
          await executor.execute(session, 'ws-1', 'conv-1', 'req-1');
      expect(resultSession.status, equals(PlanStatus.failed));
      expect(resultSession.stepStates['step-1']?.status,
          equals(StepStatus.failed));
      expect(resultSession.stepStates['step-2']?.status,
          equals(StepStatus.pending));
    });

    test('PlanExecutor handles permission request pauses', () async {
      fakeToolStepExecutor.errorCode = 'PERMISSION_REQUIRED';

      final graph = const TaskGraph(
        id: 'plan-4',
        goal: 'Test Permission Pause',
        steps: [
          TaskStep(id: 'step-1', title: 'Step 1'),
        ],
      );

      final session = ExecutionSession(
        executionId: 'exec-4',
        planId: 'plan-4',
        graph: graph,
        status: PlanStatus.ready,
        stepStates: const {
          'step-1':
              StepExecutionState(stepId: 'step-1', status: StepStatus.pending),
        },
        startedAt: DateTime.now(),
      );

      final resultSession =
          await executor.execute(session, 'ws-1', 'conv-1', 'req-1');
      expect(resultSession.status, equals(PlanStatus.waitingPermission));
      expect(resultSession.stepStates['step-1']?.status,
          equals(StepStatus.pending));
    });
  });
}
