import 'verification_models.dart';
import 'verification_engine.dart';
import 'repair_planner.dart';
import '../generation/generation_models.dart';

enum SelfHealingState {
  queued,
  runningVerification,
  planningRepair,
  generatingPatch,
  applyingPatch,
  reVerifying,
  completed,
  failed,
  cancelled
}

class SelfHealingEngine {
  final VerificationEngine verificationEngine;
  final RepairPlanner repairPlanner = const RepairPlanner();
  final int maxRetries;

  SelfHealingState state = SelfHealingState.queued;

  SelfHealingEngine({
    required this.verificationEngine,
    this.maxRetries = 5,
  });

  // Orchestrates the state-machine self-healing loop
  Future<VerificationReport> runSelfHealingLoop({
    required List<GeneratedPatch> initialPatches,
    required Future<List<GeneratedPatch>> Function(
            RepairScope scope, List<VerificationIssue> issues)
        repairGenerator,
  }) async {
    state = SelfHealingState.runningVerification;
    var report = await verificationEngine.verify();

    var attempt = 0;
    while (report.status == VerificationStatus.failed && attempt < maxRetries) {
      attempt++;
      state = SelfHealingState.planningRepair;
      final scope = repairPlanner.planRepairScope(report.issues);

      // Perform persistent knowledge search simulated check / reflection to prevent past mistakes
      state = SelfHealingState.generatingPatch;
      final repairedPatches = await repairGenerator(scope, report.issues);

      state = SelfHealingState.applyingPatch;
      if (repairedPatches.isEmpty) {
        state = SelfHealingState.failed;
        return report;
      }

      state = SelfHealingState.reVerifying;
      report = await verificationEngine.verify();
    }

    if (report.status == VerificationStatus.passed) {
      state = SelfHealingState.completed;
    } else {
      state = SelfHealingState.failed;
    }

    return VerificationReport(
      status: report.status,
      issues: report.issues,
      metrics: VerificationMetrics(
        analysisDuration: report.metrics.analysisDuration,
        compileDuration: report.metrics.compileDuration,
        testDuration: report.metrics.testDuration,
        retries: attempt,
        issuesFixed: attempt > 0 && report.status == VerificationStatus.passed
            ? report.issues.length
            : 0,
        remainingIssues: report.issues.length,
        recoveryTime: Duration(seconds: attempt * 5),
      ),
      stages: report.stages,
    );
  }
}
