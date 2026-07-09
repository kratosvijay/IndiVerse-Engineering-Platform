import 'reflection_context.dart';
import 'reflection_result.dart';
import '../workflow/execution_state.dart';
import '../../knowledge/retriever_pipeline.dart';

abstract class ReflectionStrategy {
  int get priority;
  bool matches(ReflectionContext context);
  Future<ReflectionResult> evaluate(ReflectionContext context);
}

class RetryReflectionStrategy implements ReflectionStrategy {
  @override
  int get priority => 10;

  @override
  bool matches(ReflectionContext context) {
    return context.stepState.status == StepStatus.failed &&
        context.stepState.retryCount < context.activeStep.policy.maxRetries;
  }

  @override
  Future<ReflectionResult> evaluate(ReflectionContext context) async {
    final nextRetry = context.stepState.retryCount + 1;
    return ReflectionResult(
      decision: ReflectionDecision.retryCurrentStep,
      reasoning: "Step failed. Retry attempt $nextRetry of ${context.activeStep.policy.maxRetries} scheduled.",
    );
  }
}

class ModifyPlanStrategy implements ReflectionStrategy {
  @override
  int get priority => 20;

  @override
  bool matches(ReflectionContext context) {
    // If the step failed due to missing tools, specific known errors, or diagnostics, we matches.
    final error = context.lastFailure ?? '';
    return context.stepState.status == StepStatus.failed &&
        (error.contains('diagnostic') || error.contains('modify_plan') || error.contains('analyze'));
  }

  @override
  Future<ReflectionResult> evaluate(ReflectionContext context) async {
    return const ReflectionResult(
      decision: ReflectionDecision.insertSteps,
      reasoning: "Step failed with diagnostic error. Inserting recovery step before retrying.",
      insertedSteps: [],
    );
  }
}

class AskAIStrategy implements ReflectionStrategy {
  @override
  int get priority => 30;

  @override
  bool matches(ReflectionContext context) {
    final error = context.lastFailure ?? '';
    return context.stepState.status == StepStatus.failed && error.contains('ask_ai');
  }

  @override
  Future<ReflectionResult> evaluate(ReflectionContext context) async {
    return const ReflectionResult(
      decision: ReflectionDecision.askAI,
      reasoning: "Unrecoverable structural step failure. Delegating details to LLM for planning correction.",
    );
  }
}

class FailStrategy implements ReflectionStrategy {
  @override
  int get priority => 100; // lowest priority, catch-all fallback for failures

  @override
  bool matches(ReflectionContext context) {
    return context.stepState.status == StepStatus.failed;
  }

  @override
  Future<ReflectionResult> evaluate(ReflectionContext context) async {
    return ReflectionResult(
      decision: ReflectionDecision.failExecution,
      reasoning: "Step failed and no other recovery strategies matched. Retry limit: ${context.activeStep.policy.maxRetries}.",
    );
  }
}

class KnowledgeReflectionStrategy implements ReflectionStrategy {
  final RetrieverPipeline? retriever;

  const KnowledgeReflectionStrategy({this.retriever});

  @override
  int get priority => 8;

  @override
  bool matches(ReflectionContext context) {
    return context.stepState.status == StepStatus.failed && retriever != null;
  }

  @override
  Future<ReflectionResult> evaluate(ReflectionContext context) async {
    final failure = context.lastFailure ?? '';
    final relevantContext = await retriever!.retrieveAndBuildContext(failure, limit: 1);

    if (relevantContext.isNotEmpty) {
      return ReflectionResult(
        decision: ReflectionDecision.retryCurrentStep,
        reasoning: "Retrying with long-term memory match:\n$relevantContext",
      );
    }

    final nextRetry = context.stepState.retryCount + 1;
    return ReflectionResult(
      decision: ReflectionDecision.retryCurrentStep,
      reasoning: "No matching failure solutions in long-term memory. Failover to standard retry attempt $nextRetry.",
    );
  }
}
