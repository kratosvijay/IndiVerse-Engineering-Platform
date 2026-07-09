import 'verification_models.dart';
import 'diagnostics_parser.dart';

abstract interface class VerificationRunner {
  Future<VerificationReport> analyze();
  Future<VerificationReport> compile();
  Future<VerificationReport> test();
}

class LocalVerificationRunner implements VerificationRunner {
  final DiagnosticsParser parser = DiagnosticsParser();
  final String mockAnalyzeOutput;
  final String mockCompileOutput;
  final String mockTestOutput;

  LocalVerificationRunner({
    this.mockAnalyzeOutput = '',
    this.mockCompileOutput = '',
    this.mockTestOutput = '',
  });

  @override
  Future<VerificationReport> analyze() async {
    final issues = parser.parse(mockAnalyzeOutput, origin: 'analyzer');
    final status =
        issues.isEmpty ? VerificationStatus.passed : VerificationStatus.failed;

    return VerificationReport(
      status: status,
      issues: issues,
      metrics: const VerificationMetrics(
        analysisDuration: Duration(milliseconds: 200),
        compileDuration: Duration.zero,
        testDuration: Duration.zero,
        retries: 0,
        issuesFixed: 0,
        remainingIssues: 0,
        recoveryTime: Duration.zero,
      ),
      stages: [
        VerificationStageResult(
          stage: VerificationStage.analyzing,
          status: status,
          duration: const Duration(milliseconds: 200),
          issuesCount: issues.length,
        ),
      ],
    );
  }

  @override
  Future<VerificationReport> compile() async {
    final issues = parser.parse(mockCompileOutput, origin: 'compiler');
    final status =
        issues.isEmpty ? VerificationStatus.passed : VerificationStatus.failed;

    return VerificationReport(
      status: status,
      issues: issues,
      metrics: const VerificationMetrics(
        analysisDuration: Duration.zero,
        compileDuration: Duration(milliseconds: 300),
        testDuration: Duration.zero,
        retries: 0,
        issuesFixed: 0,
        remainingIssues: 0,
        recoveryTime: Duration.zero,
      ),
      stages: [
        VerificationStageResult(
          stage: VerificationStage.compiling,
          status: status,
          duration: const Duration(milliseconds: 300),
          issuesCount: issues.length,
        ),
      ],
    );
  }

  @override
  Future<VerificationReport> test() async {
    final issues = parser.parse(mockTestOutput, origin: 'test');
    final status =
        issues.isEmpty ? VerificationStatus.passed : VerificationStatus.failed;

    return VerificationReport(
      status: status,
      issues: issues,
      metrics: const VerificationMetrics(
        analysisDuration: Duration.zero,
        compileDuration: Duration.zero,
        testDuration: Duration(milliseconds: 400),
        retries: 0,
        issuesFixed: 0,
        remainingIssues: 0,
        recoveryTime: Duration.zero,
      ),
      stages: [
        VerificationStageResult(
          stage: VerificationStage.testing,
          status: status,
          duration: const Duration(milliseconds: 400),
          issuesCount: issues.length,
        ),
      ],
    );
  }
}

class VerificationEngine {
  final VerificationRunner runner;

  const VerificationEngine({required this.runner});

  // Coordinates execution of all validation pipeline stages
  Future<VerificationReport> verify() async {
    final analyzeRep = await runner.analyze();
    if (analyzeRep.status == VerificationStatus.failed) {
      return analyzeRep;
    }

    final compileRep = await runner.compile();
    if (compileRep.status == VerificationStatus.failed) {
      return compileRep;
    }

    final testRep = await runner.test();

    final allIssues = [
      ...analyzeRep.issues,
      ...compileRep.issues,
      ...testRep.issues,
    ];

    final status = allIssues.isEmpty
        ? VerificationStatus.passed
        : VerificationStatus.failed;

    return VerificationReport(
      status: status,
      issues: allIssues,
      metrics: VerificationMetrics(
        analysisDuration: analyzeRep.metrics.analysisDuration,
        compileDuration: compileRep.metrics.compileDuration,
        testDuration: testRep.metrics.testDuration,
        retries: 0,
        issuesFixed: 0,
        remainingIssues: allIssues.length,
        recoveryTime: Duration.zero,
      ),
      stages: [
        ...analyzeRep.stages,
        ...compileRep.stages,
        ...testRep.stages,
      ],
    );
  }
}

class VerificationEngineRegistry {
  static VerificationEngine? _active;
  static VerificationEngine? get active => _active;
  static set active(VerificationEngine? engine) => _active = engine;

  static final Map<String, VerificationEngine> _registry = {};
  static void register(String workspaceId, VerificationEngine engine) {
    _registry[workspaceId] = engine;
    _active ??= engine;
  }

  static VerificationEngine? get(String workspaceId) => _registry[workspaceId];
  static void clear() {
    _registry.clear();
    _active = null;
  }
}
