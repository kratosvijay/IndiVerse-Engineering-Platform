import '../planning/planning_models.dart';
import '../../diagnostics/diagnostic_models.dart';

enum GenerationStatus {
  queued,
  generating,
  validating,
  reviewing,
  completed,
  failed,
  cancelled
}

class GeneratedPatch {
  final String filePath;
  final String originalText;
  final String generatedText;
  final List<TextEdit> edits;
  final bool createsFile;
  final bool deletesFile;

  const GeneratedPatch({
    required this.filePath,
    required this.originalText,
    required this.generatedText,
    required this.edits,
    this.createsFile = false,
    this.deletesFile = false,
  });

  Map<String, dynamic> toJson() => {
        'filePath': filePath,
        'originalText': originalText,
        'generatedText': generatedText,
        'createsFile': createsFile,
        'deletesFile': deletesFile,
      };
}

class ReviewResult {
  final double styleScore;
  final double securityScore;
  final double performanceScore;
  final double architectureScore;
  final double documentationScore;
  final String overallDecision; // e.g. "Approve", "Regenerate", "Escalate"

  const ReviewResult({
    required this.styleScore,
    required this.securityScore,
    required this.performanceScore,
    required this.architectureScore,
    required this.documentationScore,
    required this.overallDecision,
  });

  Map<String, dynamic> toJson() => {
        'styleScore': styleScore,
        'securityScore': securityScore,
        'performanceScore': performanceScore,
        'architectureScore': architectureScore,
        'documentationScore': documentationScore,
        'overallDecision': overallDecision,
      };
}

class GenerationMetrics {
  final int tokens;
  final Duration duration;
  final int retries;
  final int files;
  final int loc;

  const GenerationMetrics({
    required this.tokens,
    required this.duration,
    required this.retries,
    required this.files,
    required this.loc,
  });

  Map<String, dynamic> toJson() => {
        'tokens': tokens,
        'durationMs': duration.inMilliseconds,
        'retries': retries,
        'files': files,
        'loc': loc,
      };
}

class GenerationSession {
  final String sessionId;
  final ExecutionPlan plan;
  final GenerationStatus status;
  final String activeTask;
  final Map<String, String> checkpoints; // path -> backupOriginalText
  final List<GeneratedPatch> generatedPatches;
  final GenerationMetrics metrics;
  final String? failureReason;

  const GenerationSession({
    required this.sessionId,
    required this.plan,
    required this.status,
    required this.activeTask,
    required this.checkpoints,
    required this.generatedPatches,
    required this.metrics,
    this.failureReason,
  });

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'status': status.name,
        'activeTask': activeTask,
        'checkpointsCount': checkpoints.length,
        'patches': generatedPatches.map((p) => p.toJson()).toList(),
        'metrics': metrics.toJson(),
        'failureReason': failureReason,
      };
}
