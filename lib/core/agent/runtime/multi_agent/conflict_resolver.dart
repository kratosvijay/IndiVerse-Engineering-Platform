enum ConflictResolution {
  merged,
  manualReview,
  retry,
  replan
}

class AgentFileEdit {
  final String agentId;
  final String filePath;
  final String content;
  final DateTime timestamp;

  const AgentFileEdit({
    required this.agentId,
    required this.filePath,
    required this.content,
    required this.timestamp,
  });
}

class ConflictResolver {
  // Detects concurrent modifications to the same file path and evaluates resolution strategy
  ConflictResolution detectAndResolve(List<AgentFileEdit> edits) {
    if (edits.length <= 1) {
      return ConflictResolution.merged;
    }

    final uniquePaths = edits.map((e) => e.filePath).toSet();
    if (uniquePaths.length < edits.length) {
      // Multiple agents edited the same file!
      final firstContent = edits.first.content;
      final allSame = edits.every((e) => e.content == firstContent);
      if (allSame) {
        // Redundant edit, can merge safely
        return ConflictResolution.merged;
      }
      
      // Let's decide resolution strategy based on timestamps or content similarity
      // If edits happened within a close window, we replan/retry or request review
      final timeWindow = edits.last.timestamp.difference(edits.first.timestamp).inSeconds.abs();
      if (timeWindow < 10) {
        return ConflictResolution.retry;
      }
      return ConflictResolution.replan;
    }

    return ConflictResolution.merged;
  }
}
