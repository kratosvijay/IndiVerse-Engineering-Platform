import '../workflow/task_step.dart';

enum ReflectionDecision {
  continueExecution,
  retryCurrentStep,
  insertSteps,
  replaceSteps,
  skipStep,
  askUser,
  askAI,
  failExecution,
}

class ReflectionResult {
  final ReflectionDecision decision;
  final List<TaskStep> insertedSteps;
  final List<TaskStep> replacementSteps;
  final String reasoning;

  const ReflectionResult({
    required this.decision,
    this.insertedSteps = const [],
    this.replacementSteps = const [],
    required this.reasoning,
  });
}
