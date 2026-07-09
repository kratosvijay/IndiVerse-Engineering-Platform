import 'dart:async';
import '../../prompt/prompt_pipeline.dart';
import 'execution_state.dart';
import 'step_executor.dart';
import 'ready_step_scheduler.dart';
import 'plan_event.dart';
import 'task_step.dart';
import '../runtime/reflection_engine.dart';
import '../runtime/reflection_context.dart';
import '../runtime/reflection_result.dart';
import '../runtime/plan_mutation_engine.dart';
import '../runtime/agent_runtime.dart';
import '../runtime/agent_runtime_event.dart' as re;
import '../../workspace/workspace_intelligence.dart';

class PlanExecutor {
  final StepExecutor stepExecutor;
  final ReadyStepScheduler scheduler = ReadyStepScheduler();
  final ReflectionEngine reflectionEngine;
  final PlanMutationEngine mutationEngine;
  AgentRuntime? runtimeHook;
  
  final StreamController<PlanEvent> _eventController =
      StreamController<PlanEvent>.broadcast();

  bool _isPaused = false;
  bool _isCancelled = false;

  PlanExecutor(
    this.stepExecutor, {
    ReflectionEngine? reflectionEngine,
    PlanMutationEngine? mutationEngine,
  })  : reflectionEngine = reflectionEngine ?? ReflectionEngine(),
        mutationEngine = mutationEngine ?? PlanMutationEngine();

  Stream<PlanEvent> get progressEvents => _eventController.stream;

  void cancel() {
    _isCancelled = true;
  }

  void pause() {
    _isPaused = true;
  }

  void resume() {
    _isPaused = false;
  }

  Future<ExecutionSession> execute(
    ExecutionSession initialSession,
    String workspaceId,
    String conversationId,
    String requestId,
  ) async {
    _isCancelled = false;
    _isPaused = false;

    var session = initialSession.copyWith(status: PlanStatus.running);
    _eventController.add(PlanStartedEvent(
      planId: session.planId,
      executionId: session.executionId,
      timestamp: DateTime.now(),
      session: session,
    ));

    final token = CancellationToken();

    while (session.status == PlanStatus.running) {
      if (_isCancelled) {
        session = session.copyWith(status: PlanStatus.cancelled);
        _eventController.add(PlanStatusChangedEvent(
          planId: session.planId,
          executionId: session.executionId,
          timestamp: DateTime.now(),
          status: PlanStatus.cancelled,
        ));
        break;
      }

      while (_isPaused && !_isCancelled) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }

      // 1. Skip blocked steps using the scheduler
      final blocked = scheduler.getBlockedSteps(session);
      for (final step in blocked) {
        final state = session.stepStates[step.id]!;
        if (state.status == StepStatus.pending) {
          final updatedState = state.copyWith(status: StepStatus.skipped);
          session = session.copyWith(
            stepStates: Map<String, StepExecutionState>.from(session.stepStates)
              ..[step.id] = updatedState,
          );
          _eventController.add(StepSkippedEvent(
            planId: session.planId,
            executionId: session.executionId,
            timestamp: DateTime.now(),
            stepId: step.id,
          ));
        }
      }

      // 2. Fetch ready steps
      final readySteps = scheduler.getReadySteps(session);

      if (readySteps.isEmpty) {
        final allDone = session.stepStates.values.every((s) =>
            s.status == StepStatus.completed ||
            s.status == StepStatus.failed ||
            s.status == StepStatus.skipped);

        if (allDone) {
          final hasFailures = session.stepStates.values
              .any((s) => s.status == StepStatus.failed);
          session = session.copyWith(
            status: hasFailures ? PlanStatus.failed : PlanStatus.completed,
            completedAt: DateTime.now(),
          );
          _eventController.add(PlanCompletedEvent(
            planId: session.planId,
            executionId: session.executionId,
            timestamp: DateTime.now(),
            session: session,
          ));
        }
        break;
      }

      // 3. Process ready steps sequentially
      for (final step in readySteps) {
        final stepState = session.stepStates[step.id]!;
        final updatedRunning = stepState.copyWith(status: StepStatus.running);
        session = session.copyWith(
          stepStates: Map<String, StepExecutionState>.from(session.stepStates)
            ..[step.id] = updatedRunning,
        );

        _eventController.add(StepStartedEvent(
          planId: session.planId,
          executionId: session.executionId,
          timestamp: DateTime.now(),
          stepId: step.id,
        ));

        try {
          final result = await stepExecutor.execute(
            step,
            workspaceId,
            conversationId,
            requestId,
            token,
          );

          if (result.success) {
            final completedState = updatedRunning.copyWith(
              status: StepStatus.completed,
              output: result.output.displayText,
            );
            session = session.copyWith(
              stepStates:
                  Map<String, StepExecutionState>.from(session.stepStates)
                    ..[step.id] = completedState,
            );
            _eventController.add(StepCompletedEvent(
              planId: session.planId,
              executionId: session.executionId,
              timestamp: DateTime.now(),
              stepId: step.id,
              output: result.output.displayText,
            ));
          } else {
            // Handle permission gate: pause on waitingPermission
            if (result.errorCode == 'PERMISSION_REQUIRED') {
              session = session.copyWith(status: PlanStatus.waitingPermission);
              final pendingState =
                  updatedRunning.copyWith(status: StepStatus.pending);
              session = session.copyWith(
                stepStates:
                    Map<String, StepExecutionState>.from(session.stepStates)
                      ..[step.id] = pendingState,
              );
              _eventController.add(PlanStatusChangedEvent(
                planId: session.planId,
                executionId: session.executionId,
                timestamp: DateTime.now(),
                status: PlanStatus.waitingPermission,
              ));
              return session; // Exit executor loop until permissions are granted
            }

            final failedState = updatedRunning.copyWith(
              status: StepStatus.failed,
              error: result.output.displayText,
              lastFailure: result.output.displayText,
              lastAttempt: DateTime.now(),
            );
            session = session.copyWith(
              stepStates:
                  Map<String, StepExecutionState>.from(session.stepStates)
                    ..[step.id] = failedState,
            );
            _eventController.add(StepFailedEvent(
              planId: session.planId,
              executionId: session.executionId,
              timestamp: DateTime.now(),
              stepId: step.id,
              error: result.output.displayText,
            ));

            final handleRes = await _handleReflection(step, session, result.output.displayText ?? '');
            session = handleRes.session;
            if (handleRes.didBreak) {
              break;
            }
          }
        } catch (e) {
          final failedState = updatedRunning.copyWith(
            status: StepStatus.failed,
            error: e.toString(),
            lastFailure: e.toString(),
            lastAttempt: DateTime.now(),
          );
          session = session.copyWith(
            stepStates: Map<String, StepExecutionState>.from(session.stepStates)
              ..[step.id] = failedState,
          );
          _eventController.add(StepFailedEvent(
            planId: session.planId,
            executionId: session.executionId,
            timestamp: DateTime.now(),
            stepId: step.id,
            error: e.toString(),
          ));

          final handleRes = await _handleReflection(step, session, e.toString());
          session = handleRes.session;
          if (handleRes.didBreak) {
            break;
          }
        }

        // Calculate progress percentage
        final totalSteps = session.graph.steps.length;
        final finishedCount = session.stepStates.values
            .where((s) =>
                s.status == StepStatus.completed ||
                s.status == StepStatus.failed ||
                s.status == StepStatus.skipped)
            .length;
        session = session.copyWith(
            progress: totalSteps == 0 ? 1.0 : finishedCount / totalSteps);

        if (session.stepStates[step.id]!.status == StepStatus.failed &&
            !step.policy.continueOnFailure) {
          session = session.copyWith(status: PlanStatus.paused);
          _eventController.add(PlanStatusChangedEvent(
            planId: session.planId,
            executionId: session.executionId,
            timestamp: DateTime.now(),
            status: PlanStatus.paused,
          ));
          break;
        }
      }
    }

    return session;
  }

  Future<ReflectionHandleResult> _handleReflection(
    TaskStep step,
    ExecutionSession currentSession,
    String errorMessage,
  ) async {
    final intel = WorkspaceIntelligenceRegistry.active;
    final snapshot = intel?.getSnapshot();

    final reflectionContext = ReflectionContext(
      goal: currentSession.graph.goal,
      session: currentSession,
      activeStep: step,
      stepState: currentSession.stepStates[step.id]!,
      lastFailure: errorMessage,
      workspaceSnapshot: snapshot,
    );

    final reflectionResult = await reflectionEngine.reflect(reflectionContext);
    var session = currentSession;

    if (reflectionResult.decision == ReflectionDecision.retryCurrentStep) {
      final currentRetryCount = session.stepStates[step.id]!.retryCount;
      final retryState = session.stepStates[step.id]!.copyWith(
        status: StepStatus.pending,
        retryCount: currentRetryCount + 1,
      );
      session = session.copyWith(
        stepStates: Map<String, StepExecutionState>.from(session.stepStates)
          ..[step.id] = retryState,
      );

      runtimeHook?.emitEvent(re.StepRetryEvent(
        executionId: session.executionId,
        goalId: session.planId,
        timestamp: DateTime.now(),
        stepId: step.id,
        retryCount: currentRetryCount + 1,
        error: errorMessage,
      ));

      runtimeHook?.updateActiveSession(session);
      return ReflectionHandleResult(session, true);
    } else if (reflectionResult.decision == ReflectionDecision.insertSteps ||
               reflectionResult.decision == ReflectionDecision.replaceSteps) {
      var newGraph = session.graph;
      final inserted = reflectionResult.insertedSteps;
      final replacements = reflectionResult.replacementSteps;

      if (reflectionResult.decision == ReflectionDecision.insertSteps && inserted.isNotEmpty) {
        newGraph = mutationEngine.insertSteps(session.graph, step.id, inserted);
      } else if (reflectionResult.decision == ReflectionDecision.replaceSteps && replacements.isNotEmpty) {
        newGraph = mutationEngine.replaceStep(session.graph, step.id, replacements);
      }

      final updatedStepStates = Map<String, StepExecutionState>.from(session.stepStates);
      for (final newStep in newGraph.steps) {
        if (!updatedStepStates.containsKey(newStep.id)) {
          updatedStepStates[newStep.id] = StepExecutionState(stepId: newStep.id);
        }
      }

      session = session.copyWith(
        graph: newGraph,
        stepStates: updatedStepStates,
      );

      runtimeHook?.emitEvent(re.PlanModifiedEvent(
        executionId: session.executionId,
        goalId: session.planId,
        timestamp: DateTime.now(),
        reasoning: reflectionResult.reasoning,
        insertedStepIds: inserted.map((s) => s.id).toList(),
        replacementStepIds: replacements.map((s) => s.id).toList(),
      ));

      runtimeHook?.updateActiveSession(session);
      return ReflectionHandleResult(session, true);
    } else if (reflectionResult.decision == ReflectionDecision.skipStep) {
      final skippedState = session.stepStates[step.id]!.copyWith(status: StepStatus.skipped);
      session = session.copyWith(
        stepStates: Map<String, StepExecutionState>.from(session.stepStates)
          ..[step.id] = skippedState,
      );
      _eventController.add(StepSkippedEvent(
        planId: session.planId,
        executionId: session.executionId,
        timestamp: DateTime.now(),
        stepId: step.id,
      ));
      runtimeHook?.updateActiveSession(session);
      return ReflectionHandleResult(session, true);
    } else if (reflectionResult.decision == ReflectionDecision.askAI) {
      session = session.copyWith(status: PlanStatus.waitingUser);
      _eventController.add(PlanStatusChangedEvent(
        planId: session.planId,
        executionId: session.executionId,
        timestamp: DateTime.now(),
        status: PlanStatus.waitingUser,
      ));
      runtimeHook?.updateActiveSession(session);
      return ReflectionHandleResult(session, true);
    } else if (reflectionResult.decision == ReflectionDecision.failExecution) {
      session = session.copyWith(status: PlanStatus.failed);
      _eventController.add(PlanStatusChangedEvent(
        planId: session.planId,
        executionId: session.executionId,
        timestamp: DateTime.now(),
        status: PlanStatus.failed,
      ));
      runtimeHook?.updateActiveSession(session);
      return ReflectionHandleResult(session, true);
    }

    return ReflectionHandleResult(session, false);
  }
}

class ReflectionHandleResult {
  final ExecutionSession session;
  final bool didBreak;

  const ReflectionHandleResult(this.session, this.didBreak);
}
