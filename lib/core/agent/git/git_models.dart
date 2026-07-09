enum GitBranchPurpose {
  feature,
  bugfix,
  hotfix,
  refactor,
  experiment
}

class GitBranch {
  final String name;
  final String baseBranch;
  final String projectId;
  final String executionId;
  final DateTime createdAt;
  final GitBranchPurpose purpose;

  const GitBranch({
    required this.name,
    required this.baseBranch,
    required this.projectId,
    required this.executionId,
    required this.createdAt,
    required this.purpose,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'baseBranch': baseBranch,
        'projectId': projectId,
        'executionId': executionId,
        'createdAt': createdAt.toIso8601String(),
        'purpose': purpose.name,
      };
}

class GitCommit {
  final String hash;
  final String message;
  final String author;
  final DateTime timestamp;
  final Map<String, String> metadata;

  const GitCommit({
    required this.hash,
    required this.message,
    required this.author,
    required this.timestamp,
    required this.metadata,
  });

  Map<String, dynamic> toJson() => {
        'hash': hash,
        'message': message,
        'author': author,
        'timestamp': timestamp.toIso8601String(),
        'metadata': metadata,
      };
}

class GitDiff {
  final String targetFile;
  final String originalText;
  final String modifiedText;

  const GitDiff({
    required this.targetFile,
    required this.originalText,
    required this.modifiedText,
  });

  Map<String, dynamic> toJson() => {
        'targetFile': targetFile,
        'originalText': originalText,
        'modifiedText': modifiedText,
      };
}

class PullRequestDraft {
  final String title;
  final String summary;
  final List<String> changes;
  final List<String> risks;
  final List<String> verificationResults;
  final List<String> adrReferences;
  final List<String> relatedTasks;

  const PullRequestDraft({
    required this.title,
    required this.summary,
    required this.changes,
    required this.risks,
    required this.verificationResults,
    required this.adrReferences,
    required this.relatedTasks,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'summary': summary,
        'changes': changes,
        'risks': risks,
        'verificationResults': verificationResults,
        'adrReferences': adrReferences,
        'relatedTasks': relatedTasks,
      };
}

class MergeConflict {
  final String filePath;
  final String conflictContent;
  final bool autoResolvable;

  const MergeConflict({
    required this.filePath,
    required this.conflictContent,
    required this.autoResolvable,
  });

  Map<String, dynamic> toJson() => {
        'filePath': filePath,
        'conflictContent': conflictContent,
        'autoResolvable': autoResolvable,
      };
}

class VerificationGateResult {
  final bool passesGates;
  final List<String> errors;
  final double overallScore;

  const VerificationGateResult({
    required this.passesGates,
    required this.errors,
    required this.overallScore,
  });

  Map<String, dynamic> toJson() => {
        'passesGates': passesGates,
        'errors': errors,
        'overallScore': overallScore,
      };
}

class GitExecutionContext {
  final String activeBranch;
  final String remoteUrl;
  final Map<String, String> localConfigs;

  const GitExecutionContext({
    required this.activeBranch,
    required this.remoteUrl,
    required this.localConfigs,
  });

  Map<String, dynamic> toJson() => {
        'activeBranch': activeBranch,
        'remoteUrl': remoteUrl,
        'localConfigs': localConfigs,
      };
}
