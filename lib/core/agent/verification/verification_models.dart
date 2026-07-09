import '../../diagnostics/diagnostic_models.dart';

enum VerificationStage {
  analyzing,
  compiling,
  testing,
  linting,
  reviewing
}

enum VerificationStatus {
  queued,
  running,
  passed,
  warning,
  failed,
  cancelled
}

enum RepairScope {
  entireProject,
  module,
  file,
  className,
  functionName,
  lines
}

class VerificationIssue {
  final String severity; // e.g. "error", "warning", "info"
  final String origin; // e.g. "analyzer", "compiler", "test"
  final String file;
  final Range range;
  final String code;
  final String message;
  final String fixHint;

  const VerificationIssue({
    required this.severity,
    required this.origin,
    required this.file,
    required this.range,
    required this.code,
    required this.message,
    required this.fixHint,
  });

  Map<String, dynamic> toJson() => {
        'severity': severity,
        'origin': origin,
        'file': file,
        'range': range.toJson(),
        'code': code,
        'message': message,
        'fixHint': fixHint,
      };
}

class VerificationStageResult {
  final VerificationStage stage;
  final VerificationStatus status;
  final Duration duration;
  final int issuesCount;

  const VerificationStageResult({
    required this.stage,
    required this.status,
    required this.duration,
    required this.issuesCount,
  });

  Map<String, dynamic> toJson() => {
        'stage': stage.name,
        'status': status.name,
        'durationMs': duration.inMilliseconds,
        'issuesCount': issuesCount,
      };
}

class VerificationMetrics {
  final Duration analysisDuration;
  final Duration compileDuration;
  final Duration testDuration;
  final int retries;
  final int issuesFixed;
  final int remainingIssues;
  final Duration recoveryTime;

  const VerificationMetrics({
    required this.analysisDuration,
    required this.compileDuration,
    required this.testDuration,
    required this.retries,
    required this.issuesFixed,
    required this.remainingIssues,
    required this.recoveryTime,
  });

  Map<String, dynamic> toJson() => {
        'analysisDurationMs': analysisDuration.inMilliseconds,
        'compileDurationMs': compileDuration.inMilliseconds,
        'testDurationMs': testDuration.inMilliseconds,
        'retries': retries,
        'issuesFixed': issuesFixed,
        'remainingIssues': remainingIssues,
        'recoveryTimeMs': recoveryTime.inMilliseconds,
      };
}

class VerificationReport {
  final VerificationStatus status;
  final List<VerificationIssue> issues;
  final VerificationMetrics metrics;
  final List<VerificationStageResult> stages;

  const VerificationReport({
    required this.status,
    required this.issues,
    required this.metrics,
    required this.stages,
  });

  Map<String, dynamic> toJson() => {
        'status': status.name,
        'issues': issues.map((i) => i.toJson()).toList(),
        'metrics': metrics.toJson(),
        'stages': stages.map((s) => s.toJson()).toList(),
      };
}
