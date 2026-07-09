import 'planning_models.dart';

class GoalAnalyzer {
  // Analyzes natural language prompts to classify intent, constraints, and priorities
  GoalAnalysis analyze(String userGoal) {
    final lower = userGoal.toLowerCase();
    GoalType type = GoalType.research;
    var priority = 'Medium';

    if (lower.contains('bug') ||
        lower.contains('fix') ||
        lower.contains('error')) {
      type = GoalType.bugfix;
      priority = 'High';
    } else if (lower.contains('refactor') || lower.contains('clean')) {
      type = GoalType.refactor;
    } else if (lower.contains('migrate') || lower.contains('migration')) {
      type = GoalType.migration;
      priority = 'High';
    } else if (lower.contains('optimize') || lower.contains('perf')) {
      type = GoalType.optimization;
    } else if (lower.contains('doc') || lower.contains('readme')) {
      type = GoalType.documentation;
      priority = 'Low';
    } else if (lower.contains('test') || lower.contains('spec')) {
      type = GoalType.testing;
    } else if (lower.contains('implement') ||
        lower.contains('create') ||
        lower.contains('add')) {
      type = GoalType.feature;
    }

    final constraints = <String>[];
    if (lower.contains('oauth') || lower.contains('auth')) {
      constraints.add('Must enforce secure token handshake.');
    }
    if (lower.contains('performance') || lower.contains('fast')) {
      constraints.add('Response time must remain under 200ms.');
    }

    final acceptanceCriteria = <String>[
      'Compilation succeeds cleanly.',
      'Core unit tests verify functionality.',
    ];
    if (type == GoalType.feature) {
      acceptanceCriteria
          .add('New features are fully integrated and routes mapped.');
    }

    return GoalAnalysis(
      goal: userGoal,
      type: type,
      constraints: constraints,
      acceptanceCriteria: acceptanceCriteria,
      priority: priority,
    );
  }
}
