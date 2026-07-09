import 'planning_models.dart';

class RiskAnalyzer {
  // Analyzes and outputs detailed risk metrics based on GoalAnalysis and ArchitectureImpact
  RiskReport analyze(GoalAnalysis goalAnalysis, ArchitectureImpact impact) {
    var complexityScore = 1.0;
    var securityRisk = 1.0;
    var architectureRisk = 1.0;
    var performanceRisk = 1.0;
    var migrationRisk = 1.0;
    var regressionRisk = 1.0;

    // Files impact increases complexity & regression risks
    complexityScore += impact.files.length * 0.5;
    regressionRisk += impact.files.length * 0.4;

    // Security triggers
    if (goalAnalysis.goal.toLowerCase().contains('auth') || goalAnalysis.goal.toLowerCase().contains('login')) {
      securityRisk += 4.0;
      complexityScore += 1.5;
    }

    // Architecture layer checks
    if (impact.services.isNotEmpty && impact.providers.isNotEmpty) {
      architectureRisk += 2.0;
    }

    // Migration / DB checks
    if (impact.database.isNotEmpty) {
      migrationRisk += 3.5;
      regressionRisk += 1.5;
    }

    // Performance limits
    if (goalAnalysis.constraints.any((c) => c.contains('200ms') || c.contains('time'))) {
      performanceRisk += 3.0;
    }

    return RiskReport(
      complexityScore: _clamp(complexityScore),
      securityRisk: _clamp(securityRisk),
      architectureRisk: _clamp(architectureRisk),
      performanceRisk: _clamp(performanceRisk),
      migrationRisk: _clamp(migrationRisk),
      regressionRisk: _clamp(regressionRisk),
    );
  }

  double _clamp(double val) {
    if (val < 1.0) return 1.0;
    if (val > 10.0) return 10.0;
    return val;
  }
}
