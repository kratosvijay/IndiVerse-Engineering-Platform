import '../workflow/task_graph.dart';
import '../runtime/multi_agent/agent_role.dart';
import 'planning_models.dart';

class TaskGraphBuilder {
  // Builds a Directed Acyclic Graph (DAG) TaskGraph from GoalAnalysis and ArchitectureImpact
  TaskGraph build(GoalAnalysis goalAnalysis, ArchitectureImpact impact) {
    final nodes = <TaskNode>[];

    final planNode = const TaskNode(
      id: 'task.plan',
      title: 'Analyze and plan dependencies',
      description: 'Formulate final execution specifications.',
      priority: 'High',
      estimatedTokens: 1000,
      estimatedLOC: 0,
      dependencies: [],
      parallelizable: false,
      agentCapability: AgentCapability.planning,
    );
    nodes.add(planNode);

    // Dynamic steps based on files/database
    final writeNode = TaskNode(
      id: 'task.code',
      title: 'Write implementation modules',
      description: 'Update the following files: ${impact.files.join(", ")}.',
      priority: goalAnalysis.priority,
      estimatedTokens: 2500,
      estimatedLOC: impact.files.length * 50,
      dependencies: const ['task.plan'],
      parallelizable: true,
      agentCapability: AgentCapability.coding,
    );
    nodes.add(writeNode);

    final reviewNode = const TaskNode(
      id: 'task.review',
      title: 'Review updates',
      description: 'Verify clean architecture code conventions.',
      priority: 'Medium',
      estimatedTokens: 1200,
      estimatedLOC: 0,
      dependencies: ['task.code'],
      parallelizable: true,
      agentCapability: AgentCapability.review,
    );
    nodes.add(reviewNode);

    final testNode = const TaskNode(
      id: 'task.test',
      title: 'Run quality verification tests',
      description: 'Verify all unit tests pass cleanly.',
      priority: 'High',
      estimatedTokens: 1500,
      estimatedLOC: 0,
      dependencies: ['task.code'],
      parallelizable: true,
      agentCapability: AgentCapability.testing,
    );
    nodes.add(testNode);

    final docNode = const TaskNode(
      id: 'task.document',
      title: 'Generate markdown docs',
      description: 'Document changes in repository walkthroughs.',
      priority: 'Low',
      estimatedTokens: 800,
      estimatedLOC: 15,
      dependencies: ['task.review', 'task.test'],
      parallelizable: true,
      agentCapability: AgentCapability.documentation,
    );
    nodes.add(docNode);

    // Map to TaskSteps
    final steps = nodes.map((n) => n.toTaskStep()).toList();

    return TaskGraph(
      id: 'graph_${goalAnalysis.type.name}',
      goal: goalAnalysis.goal,
      steps: steps,
    );
  }
}
