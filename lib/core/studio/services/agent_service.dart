import 'dart:async';
import '../../../../platform_sdk/platform_sdk.dart';
import '../../events/event_bus.dart';
import '../../agent/workflow/task_graph.dart';
import '../../agent/workflow/execution_state.dart';
import '../../agent/workflow/planner_context.dart';
import '../../agent/workflow/agent_planner.dart';
import '../../agent/workflow/step_executor.dart';
import '../../agent/workflow/plan_executor.dart';
import '../../agent/workflow/plan_event.dart';
import 'tool_execution_service.dart';

class AgentService {
  final PlatformSDK sdk;
  final EventBus eventBus;
  final ToolExecutionService toolExecutionService;

  late final AgentPlanner planner;
  late final PlanExecutor planExecutor;

  final List<ExecutionSession> _history = [];
  ExecutionSession? _activeSession;
  StreamSubscription<PlanEvent>? _eventSubscription;

  String _compatStatus = "idle";
  String? _compatActiveId;

  AgentService(this.sdk, this.eventBus, this.toolExecutionService) {
    planner = AgentPlanner();
    final stepExecutor = StepExecutor(toolExecutionService, sdk);
    planExecutor = PlanExecutor(stepExecutor);

    // Listen to plan executor events to update active session state
    _eventSubscription = planExecutor.progressEvents.listen((event) {
      if (_activeSession != null &&
          _activeSession!.executionId == event.executionId) {
        if (event is PlanStartedEvent) {
          _activeSession = event.session;
        } else if (event is PlanStatusChangedEvent) {
          _activeSession = _activeSession!.copyWith(status: event.status);
        } else if (event is StepStartedEvent) {
          final states =
              Map<String, StepExecutionState>.from(_activeSession!.stepStates);
          states[event.stepId] =
              states[event.stepId]!.copyWith(status: StepStatus.running);
          _activeSession = _activeSession!.copyWith(stepStates: states);
        } else if (event is StepCompletedEvent) {
          final states =
              Map<String, StepExecutionState>.from(_activeSession!.stepStates);
          states[event.stepId] = states[event.stepId]!.copyWith(
            status: StepStatus.completed,
            output: event.output,
          );
          _activeSession = _activeSession!.copyWith(stepStates: states);
        } else if (event is StepFailedEvent) {
          final states =
              Map<String, StepExecutionState>.from(_activeSession!.stepStates);
          states[event.stepId] = states[event.stepId]!.copyWith(
            status: StepStatus.failed,
            error: event.error,
          );
          _activeSession = _activeSession!.copyWith(stepStates: states);
        } else if (event is StepSkippedEvent) {
          final states =
              Map<String, StepExecutionState>.from(_activeSession!.stepStates);
          states[event.stepId] =
              states[event.stepId]!.copyWith(status: StepStatus.skipped);
          _activeSession = _activeSession!.copyWith(stepStates: states);
        } else if (event is PlanCompletedEvent) {
          _activeSession = event.session;
          _history.add(_activeSession!);
        }
      }
    });
  }

  void dispose() {
    _eventSubscription?.cancel();
  }

  ExecutionSession? get activeSession => _activeSession;
  List<ExecutionSession> get history => _history;

  List<Map<String, dynamic>> getAvailableWorkflows() {
    return const [
      {
        "name": "Planner",
        "description": "Constructs multi-step execution plans",
        "requiredCapabilities": ["planning"],
        "estimatedDuration": "3s",
        "requiresApproval": true,
      }
    ];
  }

  Future<TaskGraph> createPlan(PlannerContext context) async {
    return planner.plan(context);
  }

  Future<ExecutionSession> startExecution(TaskGraph graph, String workspaceId,
      String conversationId, String requestId) async {
    final execId = 'exec-${DateTime.now().millisecondsSinceEpoch}';
    final stepStates = <String, StepExecutionState>{};
    for (final step in graph.steps) {
      stepStates[step.id] = StepExecutionState(stepId: step.id);
    }

    final session = ExecutionSession(
      executionId: execId,
      planId: graph.id,
      graph: graph,
      status: PlanStatus.ready,
      stepStates: stepStates,
      startedAt: DateTime.now(),
    );

    _activeSession = session;

    scheduleMicrotask(() async {
      await planExecutor.execute(
          session, workspaceId, conversationId, requestId);
    });

    return session;
  }

  Future<ExecutionSession> pauseExecution() async {
    if (_activeSession != null) {
      planExecutor.pause();
      _activeSession = _activeSession!.copyWith(status: PlanStatus.paused);
      return _activeSession!;
    }
    throw Exception('No active planning execution session found to pause.');
  }

  Future<ExecutionSession> resumeExecution(
      String workspaceId, String conversationId, String requestId) async {
    if (_activeSession != null && _activeSession!.status == PlanStatus.paused) {
      planExecutor.resume();
      _activeSession = _activeSession!.copyWith(status: PlanStatus.running);

      scheduleMicrotask(() async {
        await planExecutor.execute(
            _activeSession!, workspaceId, conversationId, requestId);
      });
      return _activeSession!;
    }
    throw Exception('No paused execution session found to resume.');
  }

  Future<ExecutionSession> retryExecution(
      String workspaceId, String conversationId, String requestId) async {
    if (_activeSession != null &&
        (_activeSession!.status == PlanStatus.failed ||
            _activeSession!.status == PlanStatus.paused)) {
      _activeSession = _activeSession!.copyWith(status: PlanStatus.running);

      scheduleMicrotask(() async {
        await planExecutor.execute(
            _activeSession!, workspaceId, conversationId, requestId);
      });
      return _activeSession!;
    }
    throw Exception('No failed or paused execution session found to retry.');
  }

  Future<ExecutionSession> cancelExecution() async {
    if (_activeSession != null) {
      planExecutor.cancel();
      _activeSession = _activeSession!.copyWith(status: PlanStatus.cancelled);
      return _activeSession!;
    }
    throw Exception('No active planning execution session found to cancel.');
  }

  // Compatibility methods for old skeleton tests
  Future<Map<String, dynamic>> runWorkflow(String name) async {
    _compatStatus = "running";
    _compatActiveId = "wf-${DateTime.now().millisecondsSinceEpoch}";

    return {
      "workflowId": _compatActiveId,
      "name": name,
      "status": "running",
      "timestamp": DateTime.now().toIso8601String(),
    };
  }

  Future<Map<String, dynamic>> cancelWorkflow(String workflowId) async {
    if (_compatActiveId == workflowId) {
      _compatStatus = "cancelled";
      return {"workflowId": workflowId, "status": "cancelled"};
    }
    throw Exception("Workflow ID not found or not active: $workflowId");
  }

  Map<String, dynamic> getStatus() {
    if (_compatActiveId != null) {
      return {
        "status": _compatStatus,
        "activeWorkflowId": _compatActiveId,
      };
    }
    return {
      "status": _activeSession?.status.name ?? "idle",
      "activeWorkflowId": _activeSession?.executionId,
    };
  }

  List<Map<String, dynamic>> getHistory() {
    return _history.map((s) => s.toJson()).toList();
  }
}
