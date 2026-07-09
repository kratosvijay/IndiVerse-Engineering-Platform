import 'review_models.dart';

abstract interface class ApprovalPolicy {
  bool evaluate(ApprovalRequest request);
}

class RiskPolicy implements ApprovalPolicy {
  @override
  bool evaluate(ApprovalRequest request) {
    // Risky changes (high LOC or low confidence) require explicit manual verification
    if (request.estimatedLoc > 1000 || request.confidence < 0.80) {
      return false; // needs approval
    }
    return true; // auto-approved
  }
}

class SecurityPolicy implements ApprovalPolicy {
  @override
  bool evaluate(ApprovalRequest request) {
    if (request.riskLevel == 'critical') {
      return false; // blocks execution without review
    }
    return true;
  }
}

class HumanApprovalEngine {
  final List<ApprovalRequest> requests = [];
  final List<ApprovalPolicy> policies;

  HumanApprovalEngine({
    required this.policies,
  });

  void submitRequest(ApprovalRequest request) {
    requests.add(request);
  }

  ApprovalRequest processOutcome(String requestId, ApprovalOutcome outcome) {
    final index = requests.indexWhere((r) => r.requestId == requestId);
    if (index == -1) {
      throw Exception('Approval request $requestId not found.');
    }

    final current = requests[index];
    ApprovalStatus status;

    switch (outcome) {
      case ApprovalOutcome.approve:
        status = ApprovalStatus.approved;
      case ApprovalOutcome.reject:
        status = ApprovalStatus.rejected;
      case ApprovalOutcome.delegate:
        status = ApprovalStatus.delegated;
      case ApprovalOutcome.escalate:
        status = ApprovalStatus.escalated;
      case ApprovalOutcome.requestChanges:
        status = ApprovalStatus.changesRequested;
      case ApprovalOutcome.pause:
        status = ApprovalStatus.pending;
    }

    final updated = ApprovalRequest(
      requestId: current.requestId,
      title: current.title,
      reason: current.reason,
      riskLevel: current.riskLevel,
      affectedFiles: current.affectedFiles,
      estimatedLoc: current.estimatedLoc,
      confidence: current.confidence,
      status: status,
      recommendedAction: current.recommendedAction,
    );

    requests[index] = updated;
    return updated;
  }
}
