import 'reflection_context.dart';
import 'reflection_result.dart';
import 'reflection_strategy.dart';

class ReflectionEngine {
  final List<ReflectionStrategy> strategies;

  ReflectionEngine({List<ReflectionStrategy>? customStrategies})
      : strategies = customStrategies ??
            [
              RetryReflectionStrategy(),
              ModifyPlanStrategy(),
              AskAIStrategy(),
              FailStrategy(),
            ] {
    // Sort by priority (lowest number first = highest priority)
    strategies.sort((a, b) => a.priority.compareTo(b.priority));
  }

  Future<ReflectionResult> reflect(ReflectionContext context) async {
    for (final strategy in strategies) {
      if (strategy.matches(context)) {
        return strategy.evaluate(context);
      }
    }
    return const ReflectionResult(
      decision: ReflectionDecision.continueExecution,
      reasoning: "Execution proceeding. No failure strategies matched.",
    );
  }
}
