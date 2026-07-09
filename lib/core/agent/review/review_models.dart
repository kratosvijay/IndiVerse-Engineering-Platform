enum ReviewCategory {
  architecture,
  performance,
  security,
  maintainability,
  readability,
  testability,
  documentation
}

enum DecisionAction {
  execute,
  askUser,
  replan,
  requestReview,
  rollback,
  abort,
  defer
}

enum ApprovalStatus {
  pending,
  approved,
  rejected,
  delegated,
  escalated,
  changesRequested
}

enum ConventionType {
  naming,
  folderLayout,
  architecture,
  dependencyInjection,
  testing,
  formatting,
  stateManagement
}

enum ApprovalOutcome {
  approve,
  reject,
  delegate,
  requestChanges,
  pause,
  escalate
}

class ReviewMetric {
  final ReviewCategory category;
  final double score;
  final List<String> reasons;
  final List<String> recommendations;
  final double confidence;

  const ReviewMetric({
    required this.category,
    required this.score,
    required this.reasons,
    required this.recommendations,
    required this.confidence,
  });

  Map<String, dynamic> toJson() => {
        'category': category.name,
        'score': score,
        'reasons': reasons,
        'recommendations': recommendations,
        'confidence': confidence,
      };
}

class ReviewReport {
  final Map<ReviewCategory, ReviewMetric> metrics;
  final double overallScore;

  const ReviewReport({
    required this.metrics,
    required this.overallScore,
  });

  Map<String, dynamic> toJson() => {
        'metrics': metrics.map((k, v) => MapEntry(k.name, v.toJson())),
        'overallScore': overallScore,
      };
}

class ConfidenceScoreReport {
  final double planning;
  final double generation;
  final double verification;
  final double repair;
  final double deployment;
  final double knowledge;
  final double reflection;
  final double overall;

  const ConfidenceScoreReport({
    required this.planning,
    required this.generation,
    required this.verification,
    required this.repair,
    required this.deployment,
    required this.knowledge,
    required this.reflection,
    required this.overall,
  });

  Map<String, dynamic> toJson() => {
        'planning': planning,
        'generation': generation,
        'verification': verification,
        'repair': repair,
        'deployment': deployment,
        'knowledge': knowledge,
        'reflection': reflection,
        'overall': overall,
      };
}

class DecisionContext {
  final ReviewReport review;
  final ConfidenceScoreReport confidence;
  final Map<String, dynamic> verificationReport;
  final int estimatedLoc;
  final bool hasSecurityRisk;

  const DecisionContext({
    required this.review,
    required this.confidence,
    required this.verificationReport,
    required this.estimatedLoc,
    required this.hasSecurityRisk,
  });
}

class DecisionRecord {
  final String decisionId;
  final String? parentDecisionId;
  final DateTime timestamp;
  final Duration duration;
  final String trigger;
  final DecisionAction action;
  final double confidence;
  final String outcomeReason;

  const DecisionRecord({
    required this.decisionId,
    required this.parentDecisionId,
    required this.timestamp,
    required this.duration,
    required this.trigger,
    required this.action,
    required this.confidence,
    required this.outcomeReason,
  });

  Map<String, dynamic> toJson() => {
        'decisionId': decisionId,
        'parentDecisionId': parentDecisionId,
        'timestamp': timestamp.toIso8601String(),
        'durationMs': duration.inMilliseconds,
        'trigger': trigger,
        'action': action.name,
        'confidence': confidence,
        'outcomeReason': outcomeReason,
      };
}

class ApprovalRequest {
  final String requestId;
  final String title;
  final String reason;
  final String riskLevel;
  final List<String> affectedFiles;
  final int estimatedLoc;
  final double confidence;
  final ApprovalStatus status;
  final String recommendedAction;

  const ApprovalRequest({
    required this.requestId,
    required this.title,
    required this.reason,
    required this.riskLevel,
    required this.affectedFiles,
    required this.estimatedLoc,
    required this.confidence,
    required this.status,
    required this.recommendedAction,
  });

  Map<String, dynamic> toJson() => {
        'requestId': requestId,
        'title': title,
        'reason': reason,
        'riskLevel': riskLevel,
        'affectedFiles': affectedFiles,
        'estimatedLoc': estimatedLoc,
        'confidence': confidence,
        'status': status.name,
        'recommendedAction': recommendedAction,
      };
}

class ProjectConvention {
  final ConventionType type;
  final String name;
  final String pattern;
  final List<String> examples;

  const ProjectConvention({
    required this.type,
    required this.name,
    required this.pattern,
    required this.examples,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'name': name,
        'pattern': pattern,
        'examples': examples,
      };
}

class ArchitectureDiff {
  final List<String> addedServices;
  final List<String> removedServices;
  final List<String> addedRoutes;
  final List<String> dependencyChanges;
  final List<String> breakingChanges;

  const ArchitectureDiff({
    required this.addedServices,
    required this.removedServices,
    required this.addedRoutes,
    required this.dependencyChanges,
    required this.breakingChanges,
  });

  Map<String, dynamic> toJson() => {
        'addedServices': addedServices,
        'removedServices': removedServices,
        'addedRoutes': addedRoutes,
        'dependencyChanges': dependencyChanges,
        'breakingChanges': breakingChanges,
      };
}

class ExplainabilityTrace {
  final String actionId;
  final String whyExplanation;
  final List<String> alternativesConsidered;
  final Map<String, dynamic> tradeoffs;
  final List<String> referenceSymbols;

  const ExplainabilityTrace({
    required this.actionId,
    required this.whyExplanation,
    required this.alternativesConsidered,
    required this.tradeoffs,
    required this.referenceSymbols,
  });

  Map<String, dynamic> toJson() => {
        'actionId': actionId,
        'whyExplanation': whyExplanation,
        'alternativesConsidered': alternativesConsidered,
        'tradeoffs': tradeoffs,
        'referenceSymbols': referenceSymbols,
      };
}
