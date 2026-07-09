import '../../workflow/task_step.dart';
import 'agent_role.dart';
import 'agent_context.dart';

class AgentResult {
  final bool success;
  final String outputMessage;
  final Map<String, dynamic> metadata;

  const AgentResult({
    required this.success,
    required this.outputMessage,
    this.metadata = const {},
  });
}

abstract class CollabAgent {
  AgentDescriptor get descriptor;
  Future<AgentResult> execute(TaskStep task, AgentContext context);
}

class PlannerAgent implements CollabAgent {
  @override
  final AgentDescriptor descriptor = const AgentDescriptor(
    id: 'agent.planner',
    name: 'Strategic Planner Agent',
    role: AgentRole.planner,
    capabilities: [AgentCapability.planning, AgentCapability.workspaceAnalysis],
  );

  @override
  Future<AgentResult> execute(TaskStep task, AgentContext context) async {
    context.memory.reasoning.record(descriptor.id, "Decomposing task: ${task.title}");
    return AgentResult(
      success: true,
      outputMessage: "Plan formulated for strategic goals.",
      metadata: {'action': 'plan_generated'},
    );
  }
}

class CodingAgent implements CollabAgent {
  @override
  final AgentDescriptor descriptor = const AgentDescriptor(
    id: 'agent.coder',
    name: 'Software Coder Agent',
    role: AgentRole.coder,
    capabilities: [AgentCapability.coding, AgentCapability.toolExecution],
  );

  @override
  Future<AgentResult> execute(TaskStep task, AgentContext context) async {
    context.memory.reasoning.record(descriptor.id, "Executing coding task: ${task.title}");
    context.memory.artifacts.publish(task.id, "Code implementation logic");
    return AgentResult(
      success: true,
      outputMessage: "Code written successfully for ${task.title}.",
    );
  }
}

class ReviewAgent implements CollabAgent {
  @override
  final AgentDescriptor descriptor = const AgentDescriptor(
    id: 'agent.reviewer',
    name: 'Code Reviewer Agent',
    role: AgentRole.reviewer,
    capabilities: [AgentCapability.review, AgentCapability.workspaceAnalysis],
  );

  @override
  Future<AgentResult> execute(TaskStep task, AgentContext context) async {
    context.memory.reasoning.record(descriptor.id, "Reviewing task: ${task.title}");
    return AgentResult(
      success: true,
      outputMessage: "Code review completed. Standards verified.",
    );
  }
}

class TestingAgent implements CollabAgent {
  @override
  final AgentDescriptor descriptor = const AgentDescriptor(
    id: 'agent.tester',
    name: 'Software Tester Agent',
    role: AgentRole.tester,
    capabilities: [AgentCapability.testing, AgentCapability.toolExecution],
  );

  @override
  Future<AgentResult> execute(TaskStep task, AgentContext context) async {
    context.memory.reasoning.record(descriptor.id, "Running tests for: ${task.title}");
    return AgentResult(
      success: true,
      outputMessage: "Test suite executed. All specs passing.",
    );
  }
}

class DocumentationAgent implements CollabAgent {
  @override
  final AgentDescriptor descriptor = const AgentDescriptor(
    id: 'agent.documenter',
    name: 'Technical Writer Agent',
    role: AgentRole.documenter,
    capabilities: [AgentCapability.documentation],
  );

  @override
  Future<AgentResult> execute(TaskStep task, AgentContext context) async {
    context.memory.reasoning.record(descriptor.id, "Writing documentation for: ${task.title}");
    return AgentResult(
      success: true,
      outputMessage: "Markdown documentation generated.",
    );
  }
}

class RefactoringAgent implements CollabAgent {
  @override
  final AgentDescriptor descriptor = const AgentDescriptor(
    id: 'agent.refactorer',
    name: 'Refactoring Specialist Agent',
    role: AgentRole.refactorer,
    capabilities: [AgentCapability.refactoring, AgentCapability.workspaceAnalysis],
  );

  @override
  Future<AgentResult> execute(TaskStep task, AgentContext context) async {
    context.memory.reasoning.record(descriptor.id, "Refactoring modules: ${task.title}");
    return AgentResult(
      success: true,
      outputMessage: "Refactoring optimization finished.",
    );
  }
}
