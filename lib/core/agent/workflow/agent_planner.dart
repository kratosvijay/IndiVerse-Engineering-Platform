import 'task_graph.dart';
import 'task_step.dart';
import 'planner_context.dart';

abstract class PlannerRule {
  bool matches(PlannerContext context);
  TaskGraph buildPlan(String planId, PlannerContext context);
}

class FixDiagnosticsRule implements PlannerRule {
  @override
  bool matches(PlannerContext context) {
    final lower = context.goal.toLowerCase();
    return lower.contains('analyzer') ||
        lower.contains('fix errors') ||
        lower.contains('diagnostics');
  }

  @override
  TaskGraph buildPlan(String planId, PlannerContext context) {
    return TaskGraph(
      id: planId,
      goal: context.goal,
      steps: const [
        TaskStep(
          id: 'step-1',
          title: 'Run static analysis to identify warnings and errors',
          toolId: 'diagnostics.list',
          arguments: {'path': '.'},
        ),
        TaskStep(
          id: 'step-2',
          title: 'Search files for the problematic code locations',
          toolId: 'workspace.search',
          arguments: {'query': 'class'},
          dependencies: ['step-1'],
        ),
        TaskStep(
          id: 'step-3',
          title: 'Apply necessary code fixes to resolve static errors',
          toolId: 'editor.replace',
          dependencies: ['step-2'],
        ),
        TaskStep(
          id: 'step-4',
          title: 'Verify platform rules pass cleanly',
          toolId: 'git.status',
          dependencies: ['step-3'],
        )
      ],
    );
  }
}

class SearchAndModifyRule implements PlannerRule {
  @override
  bool matches(PlannerContext context) {
    final lower = context.goal.toLowerCase();
    return lower.contains('search') ||
        lower.contains('modify') ||
        lower.contains('replace');
  }

  @override
  TaskGraph buildPlan(String planId, PlannerContext context) {
    return TaskGraph(
      id: planId,
      goal: context.goal,
      steps: [
        TaskStep(
          id: 'step-1',
          title: 'Search references related to goal: "${context.goal}"',
          toolId: 'workspace.search',
          arguments: {'query': context.goal.split(' ').first},
        ),
        const TaskStep(
          id: 'step-2',
          title: 'Analyze and check repository status',
          toolId: 'git.status',
          dependencies: ['step-1'],
        )
      ],
    );
  }
}

class GenericRule implements PlannerRule {
  @override
  bool matches(PlannerContext context) => true;

  @override
  TaskGraph buildPlan(String planId, PlannerContext context) {
    return TaskGraph(
      id: planId,
      goal: context.goal,
      steps: [
        const TaskStep(
          id: 'step-1',
          title: 'Scan workspace structure and configurations',
          toolId: 'git.status',
          arguments: {},
        ),
        TaskStep(
          id: 'step-2',
          title: 'Search references related to: "${context.goal}"',
          toolId: 'workspace.search',
          arguments: {'query': context.goal.split(' ').first},
          dependencies: ['step-1'],
        ),
        const TaskStep(
          id: 'step-3',
          title: 'Perform verification check',
          toolId: 'git.status',
          dependencies: ['step-2'],
        )
      ],
    );
  }
}

class AgentPlanner {
  final List<PlannerRule> _rules = [
    FixDiagnosticsRule(),
    SearchAndModifyRule(),
    GenericRule(),
  ];

  Future<TaskGraph> plan(PlannerContext context) async {
    final planId = 'plan-${DateTime.now().millisecondsSinceEpoch}';
    final rule = _rules.firstWhere((r) => r.matches(context));
    return rule.buildPlan(planId, context);
  }
}
