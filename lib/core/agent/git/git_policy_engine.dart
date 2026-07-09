import 'git_models.dart';

abstract interface class GitPolicy {
  String get name;
  VerificationGateResult evaluate(GitBranch branch, {double reviewScore = 9.5});
}

class BranchPolicy implements GitPolicy {
  const BranchPolicy();

  @override
  String get name => 'BranchPolicy';

  @override
  VerificationGateResult evaluate(GitBranch branch,
      {double reviewScore = 9.5}) {
    if (branch.name == 'main' || branch.name == 'master') {
      return const VerificationGateResult(
        passesGates: false,
        errors: [
          'Policy Violation: direct commits to main branch are forbidden.'
        ],
        overallScore: 0.0,
      );
    }
    return const VerificationGateResult(
        passesGates: true, errors: [], overallScore: 10.0);
  }
}

class VerificationPolicy implements GitPolicy {
  const VerificationPolicy();

  @override
  String get name => 'VerificationPolicy';

  @override
  VerificationGateResult evaluate(GitBranch branch,
      {double reviewScore = 9.5}) {
    if (reviewScore < 7.0) {
      return VerificationGateResult(
        passesGates: false,
        errors: [
          'Verification Policy Gate Failed: review score $reviewScore is below threshold 7.0.'
        ],
        overallScore: reviewScore,
      );
    }
    return VerificationGateResult(
        passesGates: true, errors: [], overallScore: reviewScore);
  }
}

class GitPolicyEngine {
  final List<GitPolicy> policies;

  const GitPolicyEngine({
    this.policies = const [
      BranchPolicy(),
      VerificationPolicy(),
    ],
  });

  VerificationGateResult checkCommitGates(
      GitBranch branch, double reviewScore) {
    final errors = <String>[];
    var lowestScore = 10.0;

    for (final policy in policies) {
      final res = policy.evaluate(branch, reviewScore: reviewScore);
      if (!res.passesGates) {
        errors.addAll(res.errors);
      }
      if (res.overallScore < lowestScore) {
        lowestScore = res.overallScore;
      }
    }

    return VerificationGateResult(
      passesGates: errors.isEmpty,
      errors: errors,
      overallScore: lowestScore,
    );
  }
}
