
class CommitMessageGenerator {
  const CommitMessageGenerator();

  // Generates metadata Conventional Commit messages
  String generateMessage({
    required String type, // feat, fix, refactor
    required String scope,
    required String description,
    required String projectId,
    required String executionId,
  }) {
    final cleanType = type.toLowerCase().trim();
    final cleanScope = scope.toLowerCase().trim();

    return '$cleanType($cleanScope): $description\n\n'
        'Generated-By: IndiVerse AI\n'
        'Project-ID: $projectId\n'
        'Execution-ID: $executionId';
  }
}
