import 'git_models.dart';

class MergeConflictResolver {
  const MergeConflictResolver();

  // Resolves simple conflict blocks by classifying resolvability
  MergeConflict resolveConflict(MergeConflict conflict) {
    if (!conflict.conflictContent.contains('<<<<<<<')) {
      return MergeConflict(
        filePath: conflict.filePath,
        conflictContent: conflict.conflictContent,
        autoResolvable: true,
      );
    }

    final hasConflictBlock = conflict.conflictContent.contains('=======');
    if (hasConflictBlock &&
        conflict.conflictContent.contains('// Auto-resolvable')) {
      // Simulates resolution by choosing the inbound head modification block
      final resolved = conflict.conflictContent
          .replaceAll(RegExp(r'<<<<<<<[\s\S]*?======='), '')
          .replaceAll('>>>>>>>', '')
          .trim();
      return MergeConflict(
        filePath: conflict.filePath,
        conflictContent: resolved,
        autoResolvable: true,
      );
    }

    return MergeConflict(
      filePath: conflict.filePath,
      conflictContent: conflict.conflictContent,
      autoResolvable: false, // Requires user review
    );
  }
}
