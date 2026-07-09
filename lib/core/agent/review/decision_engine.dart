import 'review_models.dart';

class DecisionEngine {
  final List<DecisionRecord> history = [];

  DecisionRecord evaluate(DecisionContext context, {String? parentDecisionId}) {
    final stopwatch = Stopwatch()..start();

    DecisionAction action;
    String reason;

    if (context.review.overallScore < 7.0 ||
        context.confidence.overall < 0.70) {
      action = DecisionAction.replan;
      reason =
          'Low code review score (${context.review.overallScore}) or low confidence (${context.confidence.overall}). Triggering replan.';
    } else if (context.hasSecurityRisk) {
      action = DecisionAction.requestReview;
      reason =
          'Security flags identified. Requesting architectural code reviews.';
    } else if (context.estimatedLoc > 500) {
      action = DecisionAction.askUser;
      reason =
          'Change size is large (${context.estimatedLoc} LOC). Prompting user for approval.';
    } else {
      action = DecisionAction.execute;
      reason = 'Governance metrics satisfied. Safe to execute autonomously.';
    }

    final record = DecisionRecord(
      decisionId: 'decision-${DateTime.now().millisecondsSinceEpoch}',
      parentDecisionId: parentDecisionId,
      timestamp: DateTime.now(),
      duration: stopwatch.elapsed,
      trigger: 'Automated Evaluation',
      action: action,
      confidence: context.confidence.overall,
      outcomeReason: reason,
    );

    history.add(record);
    return record;
  }
}
