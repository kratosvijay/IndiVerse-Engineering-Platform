import 'dart:async';
import '../workflow/plan_executor.dart';
import '../workflow/execution_state.dart';
import '../workflow/task_graph.dart';
import '../workflow/plan_event.dart' as pe;
import 'goal_manager.dart';
import 'reflection_engine.dart';
import 'agent_runtime_event.dart';

class AgentRuntime {
  final PlanExecutor planExecutor;
  final GoalManager goalManager;
  final ReflectionEngine reflectionEngine;

  final StreamController<AgentRuntimeEvent> _eventController =
      StreamController<AgentRuntimeEvent>.broadcast();

  ExecutionSession? _activeSession;
  Timer? _heartbeatTimer;
  StreamSubscription? _executorSubscription;

  AgentRuntime({
    required this.planExecutor,
    required this.goalManager,
    required this.reflectionEngine,
  });

  Stream<AgentRuntimeEvent> get events => _eventController.stream;
  ExecutionSession? get activeSession => _activeSession;
  PlanStatus get status => _activeSession?.status ?? PlanStatus.ready;

  Future<ExecutionSession> start(
    TaskGraph graph,
    String workspaceId,
    String conversationId,
    String requestId,
  ) async {
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

    // Listen to PlanExecutor events to emit AgentRuntimeEvent counterparts
    await _executorSubscription?.cancel();
    _executorSubscription = planExecutor.progressEvents.listen((event) {
      final active = _activeSession;
      if (active == null || active.executionId != event.executionId) return;

      if (event is pe.PlanStartedEvent) {
        _activeSession = event.session;
      } else if (event is pe.PlanStatusChangedEvent) {
        _activeSession = _activeSession!.copyWith(status: event.status);
      } else if (event is pe.StepStartedEvent) {
        final states = Map<String, StepExecutionState>.from(_activeSession!.stepStates);
        states[event.stepId] = states[event.stepId]!.copyWith(status: StepStatus.running);
        _activeSession = _activeSession!.copyWith(stepStates: states);

        _eventController.add(StepStartedEvent(
          executionId: event.executionId,
          goalId: event.planId,
          timestamp: event.timestamp,
          stepId: event.stepId,
        ));
      } else if (event is pe.StepCompletedEvent) {
        final states = Map<String, StepExecutionState>.from(_activeSession!.stepStates);
        states[event.stepId] = states[event.stepId]!.copyWith(
          status: StepStatus.completed,
          output: event.output,
        );
        _activeSession = _activeSession!.copyWith(stepStates: states);

        _eventController.add(StepCompletedEvent(
          executionId: event.executionId,
          goalId: event.planId,
          timestamp: event.timestamp,
          stepId: event.stepId,
          output: event.output,
        ));
      } else if (event is pe.StepFailedEvent) {
        final states = Map<String, StepExecutionState>.from(_activeSession!.stepStates);
        states[event.stepId] = states[event.stepId]!.copyWith(
          status: StepStatus.failed,
          error: event.error,
        );
        _activeSession = _activeSession!.copyWith(stepStates: states);
      } else if (event is pe.StepSkippedEvent) {
        final states = Map<String, StepExecutionState>.from(_activeSession!.stepStates);
        states[event.stepId] = states[event.stepId]!.copyWith(status: StepStatus.skipped);
        _activeSession = _activeSession!.copyWith(stepStates: states);
      } else if (event is pe.PlanCompletedEvent) {
        _activeSession = event.session;
      }
    });

    _startHeartbeats();

    try {
      final finalSession = await planExecutor.execute(
        session,
        workspaceId,
        conversationId,
        requestId,
      );
      _activeSession = finalSession;

      if (finalSession.status == PlanStatus.completed) {
        _eventController.add(GoalCompletedEvent(
          executionId: finalSession.executionId,
          goalId: finalSession.planId,
          timestamp: DateTime.now(),
          progress: 1.0,
        ));
      }

      return finalSession;
    } finally {
      _stopHeartbeats();
    }
  }

  void pause() {
    planExecutor.pause();
    if (_activeSession != null) {
      _activeSession = _activeSession!.copyWith(status: PlanStatus.paused);
      _eventController.add(HeartbeatEvent(
        executionId: _activeSession!.executionId,
        goalId: _activeSession!.planId,
        timestamp: DateTime.now(),
        progress: goalManager.calculateProgress(_activeSession!),
        statusMessage: "Execution paused",
      ));
    }
    _stopHeartbeats();
  }

  void resume(String workspaceId, String conversationId, String requestId) {
    planExecutor.resume();
    if (_activeSession != null) {
      _activeSession = _activeSession!.copyWith(status: PlanStatus.running);
      _startHeartbeats();
      scheduleMicrotask(() async {
        try {
          final finalSession = await planExecutor.execute(
            _activeSession!,
            workspaceId,
            conversationId,
            requestId,
          );
          _activeSession = finalSession;
          if (finalSession.status == PlanStatus.completed) {
            _eventController.add(GoalCompletedEvent(
              executionId: finalSession.executionId,
              goalId: finalSession.planId,
              timestamp: DateTime.now(),
              progress: 1.0,
            ));
          }
        } finally {
          _stopHeartbeats();
        }
      });
    }
  }

  void cancel() {
    planExecutor.cancel();
    if (_activeSession != null) {
      _activeSession = _activeSession!.copyWith(status: PlanStatus.cancelled);
      _eventController.add(ExecutionCancelledEvent(
        executionId: _activeSession!.executionId,
        goalId: _activeSession!.planId,
        timestamp: DateTime.now(),
      ));
    }
    _stopHeartbeats();
  }

  void emitEvent(AgentRuntimeEvent event) {
    if (event is PlanModifiedEvent && _activeSession != null) {
      // Keep session in sync with mutated graph from events if needed
    }
    _eventController.add(event);
  }

  void updateActiveSession(ExecutionSession session) {
    _activeSession = session;
  }

  void _startHeartbeats() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      final active = _activeSession;
      if (active != null) {
        String? activeStepId;
        for (final step in active.graph.steps) {
          final state = active.stepStates[step.id];
          if (state?.status == StepStatus.running) {
            activeStepId = step.id;
            break;
          }
        }

        _eventController.add(HeartbeatEvent(
          executionId: active.executionId,
          goalId: active.planId,
          timestamp: DateTime.now(),
          activeStepId: activeStepId,
          progress: goalManager.calculateProgress(active),
          statusMessage: "Agent executing: status=${active.status.name}",
        ));
      }
    });
  }

  void _stopHeartbeats() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void dispose() {
    _executorSubscription?.cancel();
    _stopHeartbeats();
    _eventController.close();
  }
}
