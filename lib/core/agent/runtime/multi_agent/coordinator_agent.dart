import 'dart:async';
import '../../../prompt/prompt_pipeline.dart';
import '../../../workspace/graph/workspace_snapshot.dart';
import '../../workflow/task_graph.dart';
import '../../workflow/task_step.dart';
import '../agent_runtime.dart';
import '../agent_runtime_event.dart';
import 'agent_role.dart';
import 'agent_context.dart';
import 'agent_registry.dart';
import 'agent_message_bus.dart';
import 'agent_memory.dart';
import 'agent_scheduler.dart';
import 'conflict_resolver.dart';
import 'execution_plan.dart';

class CoordinatorAgent {
  final String executionId;
  final String goalId;
  final AgentRegistry registry = AgentRegistry();
  final AgentMessageBus bus = AgentMessageBus();
  final SharedMemory memory = SharedMemory();
  final AgentScheduler scheduler = AgentScheduler();
  final ConflictResolver conflictResolver = ConflictResolver();

  final StreamController<AgentRuntimeEvent> _eventController =
      StreamController<AgentRuntimeEvent>.broadcast(sync: true);

  Stream<AgentRuntimeEvent> get events => _eventController.stream;

  CoordinatorAgent({
    required this.executionId,
    required this.goalId,
  });

  // Entry point: decomposes a user goal and runs the collaborative multi-agent loop
  Future<bool> runCollaboration(
    String userGoal,
    WorkspaceSnapshot snapshot,
    AgentRuntime runtime,
    CancellationToken token,
  ) async {
    _emit(AgentStartedEvent(
      executionId: executionId,
      goalId: goalId,
      timestamp: DateTime.now(),
      agentId: 'agent.coordinator',
    ));

    // Register registry agents and emit events
    for (final agent in registry.listAgents()) {
      _emit(AgentRegisteredEvent(
        executionId: executionId,
        goalId: goalId,
        timestamp: DateTime.now(),
        agentId: agent.descriptor.id,
        role: agent.descriptor.role.name,
      ));
    }

    // 1. Plan Decomposition (Construct TaskGraph DAG)
    final planStep = const TaskStep(
      id: 'step.plan',
      title: 'Formulate Architecture Plan',
      dependencies: [],
    );
    final codeStep = const TaskStep(
      id: 'step.code',
      title: 'Write Implementation Modules',
      dependencies: ['step.plan'],
    );
    final reviewStep = const TaskStep(
      id: 'step.review',
      title: 'Verify Code and Architecture Cleanliness',
      dependencies: ['step.code'],
    );
    final testStep = const TaskStep(
      id: 'step.test',
      title: 'Run Integration and Quality Tests',
      dependencies: ['step.code'],
    );
    final docStep = const TaskStep(
      id: 'step.doc',
      title: 'Write Verification Documentation',
      dependencies: ['step.review', 'step.test'],
    );

    final graph = TaskGraph(
      id: 'graph-collab',
      goal: 'Decompose user goal',
      steps: [planStep, codeStep, reviewStep, testStep, docStep],
    );

    final plan = ExecutionPlan(
      planId: 'plan-1',
      graph: graph,
      constraints: const [
        ExecutionConstraint(key: 'timeout_secs', value: '300'),
      ],
      snapshot: snapshot,
    );

    // 2. Setup Context
    final context = AgentContext(
      snapshot: snapshot,
      memory: memory,
      bus: bus,
      cancellationToken: token,
      runtime: runtime,
    );

    final orderedSteps = scheduler.resolveExecutionOrder(plan);
    final activeEdits = <AgentFileEdit>[];

    // Listen to message bus to track published artifacts and log them
    final sub = bus.messages.listen((envelope) {
      _emit(MessageSentEvent(
        executionId: executionId,
        goalId: goalId,
        timestamp: DateTime.now(),
        senderId: envelope.senderId,
        recipientId: envelope.recipientId,
      ));
    });

    bool success = true;

    try {
      for (final step in orderedSteps) {
        if (token.isCancelled) {
          success = false;
          break;
        }

        // Determine agent role to assign
        AgentRole assignedRole;
        if (step.id.contains('plan')) {
          assignedRole = AgentRole.planner;
        } else if (step.id.contains('code')) {
          assignedRole = AgentRole.coder;
        } else if (step.id.contains('review')) {
          assignedRole = AgentRole.reviewer;
        } else if (step.id.contains('test')) {
          assignedRole = AgentRole.tester;
        } else if (step.id.contains('doc')) {
          assignedRole = AgentRole.documenter;
        } else {
          assignedRole = AgentRole.refactorer;
        }

        final agents = registry.getAgentsByRole(assignedRole);
        if (agents.isEmpty) {
          success = false;
          break;
        }

        final agent = agents.first;
        _emit(AgentSpawnedEvent(
          executionId: executionId,
          goalId: goalId,
          timestamp: DateTime.now(),
          agentId: agent.descriptor.id,
          role: agent.descriptor.role.name,
        ));

        _emit(TaskAssignedEvent(
          executionId: executionId,
          goalId: goalId,
          timestamp: DateTime.now(),
          taskId: step.id,
          agentId: agent.descriptor.id,
        ));

        // Simulate execution
        final result = await agent.execute(step, context);
        _emit(TaskCompletedEvent(
          executionId: executionId,
          goalId: goalId,
          timestamp: DateTime.now(),
          taskId: step.id,
          success: result.success,
        ));

        if (!result.success) {
          success = false;
          break;
        }

        // Track artifacts and concurrent edits
        if (assignedRole == AgentRole.coder) {
          activeEdits.add(AgentFileEdit(
            agentId: agent.descriptor.id,
            filePath: 'lib/main.dart',
            content: 'void main() {}',
            timestamp: DateTime.now(),
          ));

          _emit(ArtifactPublishedEvent(
            executionId: executionId,
            goalId: goalId,
            timestamp: DateTime.now(),
            artifactId: step.id,
          ));
        }
      }

      // 3. Run Conflict Resolution if we had concurrent edits
      if (activeEdits.isNotEmpty) {
        // Let's simulate a concurrent edit conflict scenario
        activeEdits.add(AgentFileEdit(
          agentId: 'agent.refactorer',
          filePath: 'lib/main.dart',
          content: 'void main() {}',
          timestamp: DateTime.now(),
        ));

        _emit(ConflictDetectedEvent(
          executionId: executionId,
          goalId: goalId,
          timestamp: DateTime.now(),
          filePaths: const ['lib/main.dart'],
        ));

        final resolution = conflictResolver.detectAndResolve(activeEdits);
        if (resolution == ConflictResolution.merged) {
          _emit(MergeCompletedEvent(
            executionId: executionId,
            goalId: goalId,
            timestamp: DateTime.now(),
            filePaths: const ['lib/main.dart'],
          ));
        } else {
          // Retry or replan required
          success = false;
        }
      }
    } catch (e, s) {
      print("COORDINATOR ERROR: $e\n$s");
      success = false;
    } finally {
      await sub.cancel();
    }

    _emit(CoordinatorFinishedEvent(
      executionId: executionId,
      goalId: goalId,
      timestamp: DateTime.now(),
      success: success,
    ));

    _emit(AgentStoppedEvent(
      executionId: executionId,
      goalId: goalId,
      timestamp: DateTime.now(),
      agentId: 'agent.coordinator',
      success: success,
    ));

    return success;
  }

  void _emit(AgentRuntimeEvent event) {
    _eventController.add(event);
  }

  void dispose() {
    _eventController.close();
    bus.close();
  }
}
