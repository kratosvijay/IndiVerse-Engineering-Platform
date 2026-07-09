import 'dart:async';
import 'package:test/test.dart';
import 'package:indiverse_developer_platform/core/agent/workflow/task_graph.dart';
import 'package:indiverse_developer_platform/core/agent/workflow/task_step.dart';
import 'package:indiverse_developer_platform/core/agent/workflow/execution_state.dart';
import 'package:indiverse_developer_platform/core/agent/workflow/plan_executor.dart';
import 'package:indiverse_developer_platform/core/agent/workflow/step_executor.dart';
import 'package:indiverse_developer_platform/core/agent/runtime/reflection_engine.dart';
import 'package:indiverse_developer_platform/core/agent/runtime/reflection_strategy.dart';
import 'package:indiverse_developer_platform/core/agent/runtime/reflection_context.dart';
import 'package:indiverse_developer_platform/core/agent/runtime/reflection_result.dart';
import 'package:indiverse_developer_platform/core/agent/runtime/plan_mutation_engine.dart';
import 'package:indiverse_developer_platform/core/agent/runtime/goal_manager.dart';
import 'package:indiverse_developer_platform/core/agent/runtime/agent_runtime.dart';
import 'package:indiverse_developer_platform/core/agent/runtime/agent_runtime_event.dart';
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
  @override
  PermissionDecision? getDecision(String toolName) => null;
}

class FakeStepExecutor implements StepTypeExecutor {
  int executeCount = 0;
  bool shouldSucceed = true;
  int succeedOnAttempt = 0;
  String outputText = "Output";
  String errorText = "Error Details";

  @override
  Future<ToolCallResult> execute(
    TaskStep step,
    String workspaceId,
    String conversationId,
    String requestId,
    CancellationToken token,
  ) async {
    executeCount++;
    if (succeedOnAttempt > 0 && executeCount >= succeedOnAttempt) {
      shouldSucceed = true;
    }
    if (errorText == 'PERMISSION_REQUIRED') {
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
        displayText: shouldSucceed ? outputText : errorText,
        mimeType: 'text/plain',
      ),
      duration: Duration.zero,
      errorCode: shouldSucceed ? null : 'EXECUTION_FAILED',
    );
  }
}

class CustomStrategy implements ReflectionStrategy {
  @override
  int get priority => 5;

  @override
  bool matches(ReflectionContext context) {
    return context.lastFailure == 'trigger_custom';
  }

  @override
  Future<ReflectionResult> evaluate(ReflectionContext context) async {
    return const ReflectionResult(
      decision: ReflectionDecision.insertSteps,
      reasoning: "Custom recovery trigger matched.",
      insertedSteps: [
        TaskStep(id: 'inserted-1', title: 'Inserted recovery step'),
      ],
    );
  }
}

void main() {
  group('Sprint 21.7 - Autonomous Agent Execution Tests', () {
    late ReflectionEngine reflectionEngine;
    late PlanMutationEngine mutationEngine;
    late GoalManager goalManager;
    late PlanExecutor planExecutor;
    late AgentRuntime agentRuntime;
    late FakeStepExecutor fakeStepExecutor;

    setUp(() {
      reflectionEngine = ReflectionEngine(customStrategies: [
        RetryReflectionStrategy(),
        ModifyPlanStrategy(),
        AskAIStrategy(),
        FailStrategy(),
        CustomStrategy(),
      ]);
      mutationEngine = PlanMutationEngine();
      goalManager = GoalManager();

      final toolService = ToolExecutionService(
        registry: MockToolRegistry(),
        permissionStore: MockPermissionStore(),
      );

      final sdk = PlatformSDK(
        runtime: RuntimeAPI(),
        workspace: WorkspaceAPI(),
        knowledge: KnowledgeAPI(),
        agent: AgentAPI(),
        plugin: PluginAPI(),
      );

      final stepExecutor = StepExecutor(toolService, sdk);
      fakeStepExecutor = FakeStepExecutor();
      stepExecutor.registerExecutor(StepType.tool, fakeStepExecutor);

      planExecutor = PlanExecutor(
        stepExecutor,
        reflectionEngine: reflectionEngine,
        mutationEngine: mutationEngine,
      );

      agentRuntime = AgentRuntime(
        planExecutor: planExecutor,
        goalManager: goalManager,
        reflectionEngine: reflectionEngine,
      );
      planExecutor.runtimeHook = agentRuntime;
    });

    test('ReflectionEngine Strategy sorting and matching priority', () async {
      final graph = const TaskGraph(
        id: 'plan-ref',
        goal: 'Reflection matching',
        steps: [
          TaskStep(id: 'step-1', title: 'Step 1'),
        ],
      );

      final session = ExecutionSession(
        executionId: 'exec-ref',
        planId: 'plan-ref',
        graph: graph,
        status: PlanStatus.running,
        stepStates: const {
          'step-1': StepExecutionState(
            stepId: 'step-1',
            status: StepStatus.failed,
          ),
        },
        startedAt: DateTime.now(),
      );

      final context = ReflectionContext(
        goal: 'Reflection matching',
        session: session,
        activeStep: graph.steps.first,
        stepState: session.stepStates['step-1']!,
        lastFailure: 'trigger_custom',
      );

      final result = await reflectionEngine.reflect(context);
      expect(result.decision, equals(ReflectionDecision.insertSteps));
      expect(result.reasoning, contains("Custom recovery"));
      expect(result.insertedSteps.length, equals(1));
    });

    test('PlanMutationEngine functional TaskGraph modification', () {
      final graph = const TaskGraph(
        id: 'plan-mut',
        goal: 'Plan mutation',
        steps: [
          TaskStep(id: 'step-1', title: 'Step 1'),
          TaskStep(id: 'step-2', title: 'Step 2', dependencies: ['step-1']),
        ],
      );

      final insertedGraph = mutationEngine.insertSteps(
        graph,
        'step-1',
        [const TaskStep(id: 'inserted-1', title: 'Inserted Step')],
      );

      expect(insertedGraph.steps.length, equals(3));
      expect(insertedGraph.steps[1].id, equals('inserted-1'));
      expect(insertedGraph.steps[1].dependencies, contains('step-1'));
      expect(insertedGraph.steps[2].id, equals('step-2'));
      expect(insertedGraph.steps[2].dependencies, contains('inserted-1'));

      final replacedGraph = mutationEngine.replaceStep(
        graph,
        'step-1',
        [const TaskStep(id: 'replaced-1', title: 'Replaced Step')],
      );

      expect(replacedGraph.steps.length, equals(2));
      expect(replacedGraph.steps.first.id, equals('replaced-1'));
      expect(replacedGraph.steps[1].dependencies, contains('replaced-1'));
    });

    test('AgentRuntime events, heartbeats, and pause/resume lifecycle',
        () async {
      final graph = const TaskGraph(
        id: 'plan-live',
        goal: 'Lifecycle verification',
        steps: [
          TaskStep(id: 'step-1', title: 'Step 1'),
          TaskStep(id: 'step-2', title: 'Step 2', dependencies: ['step-1']),
        ],
      );

      final events = <AgentRuntimeEvent>[];
      final subscription = agentRuntime.events.listen(events.add);

      final runFuture = agentRuntime.start(graph, 'ws-1', 'conv-1', 'req-1');

      // Wait briefly for execution to run and heartbeats to start
      await Future<void>.delayed(const Duration(milliseconds: 100));

      agentRuntime.pause();
      expect(agentRuntime.status, equals(PlanStatus.paused));

      // Resume execution
      agentRuntime.resume('ws-1', 'conv-1', 'req-1');
      final finalSession = await runFuture;

      await Future<void>.delayed(const Duration(milliseconds: 100));
      await subscription.cancel();

      expect(finalSession.status, equals(PlanStatus.completed));
      expect(events.any((e) => e is HeartbeatEvent), isTrue);
      expect(events.any((e) => e is StepStartedEvent && e.stepId == 'step-1'),
          isTrue);
      expect(events.any((e) => e is GoalCompletedEvent), isTrue);
    });

    test('ReflectionEngine retry logic and successful recovery', () async {
      fakeStepExecutor.shouldSucceed = false;
      fakeStepExecutor.succeedOnAttempt = 2;
      fakeStepExecutor.errorText = "Error details"; // triggers RetryStrategy

      final graph = const TaskGraph(
        id: 'plan-retry',
        goal: 'Verify retries',
        steps: [
          TaskStep(
            id: 'step-1',
            title: 'Retry step',
            policy: ExecutionPolicy(maxRetries: 2),
          ),
        ],
      );

      final events = <AgentRuntimeEvent>[];
      final sub = agentRuntime.events.listen(events.add);

      final finalSession =
          await agentRuntime.start(graph, 'ws-1', 'conv-1', 'req-1');
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(finalSession.status, equals(PlanStatus.completed));
      expect(finalSession.stepStates['step-1']?.status,
          equals(StepStatus.completed));
      expect(events.any((e) => e is StepRetryEvent), isTrue);
    });

    test('ReflectionEngine unrecoverable failures trigger failGoal', () async {
      fakeStepExecutor.shouldSucceed = false;
      fakeStepExecutor.errorText = "unrecoverable";

      final graph = const TaskGraph(
        id: 'plan-fail',
        goal: 'Verify failure fallback',
        steps: [
          TaskStep(
            id: 'step-1',
            title: 'Fail step',
            policy: ExecutionPolicy(maxRetries: 1),
          ),
        ],
      );

      final finalSession =
          await agentRuntime.start(graph, 'ws-1', 'conv-1', 'req-1');
      expect(finalSession.status, equals(PlanStatus.failed));
      expect(
          finalSession.stepStates['step-1']?.status, equals(StepStatus.failed));
    });
  });
}
