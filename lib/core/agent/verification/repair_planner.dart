import 'verification_models.dart';

class RepairPlanner {
  const RepairPlanner();

  // Evaluates compilation/test errors to map the narrowest possible RepairScope
  RepairScope planRepairScope(List<VerificationIssue> issues) {
    if (issues.isEmpty) return RepairScope.entireProject;

    // Check if issues are isolated to specific lines or files
    var hasMultipleFiles = false;
    final primaryFile = issues.first.file;

    for (final issue in issues) {
      if (issue.file != primaryFile) {
        hasMultipleFiles = true;
        break;
      }
    }

    if (hasMultipleFiles) {
      return RepairScope.entireProject;
    }

    // Single file issue: check if lines range is narrow
    final lineRange = issues.map((i) => i.range.start.line);
    final minLine = lineRange.reduce((a, b) => a < b ? a : b);
    final maxLine = lineRange.reduce((a, b) => a > b ? a : b);

    if ((maxLine - minLine) <= 15) {
      return RepairScope.lines;
    }

    return RepairScope.file;
  }
}
