import 'verification_models.dart';
import '../../diagnostics/diagnostic_models.dart';

class DiagnosticsParser {
  // Converts raw command logs (from dart analyze or flutter test) into structured issues
  List<VerificationIssue> parse(String log, {required String origin}) {
    final issues = <VerificationIssue>[];
    final lines = log.split('\n');

    for (final line in lines) {
      if (line.isEmpty) continue;

      // Matches typical dart analyze output:
      // info - lib/main.dart:10:5 - Unused variable. - unused_local_variable
      final match = RegExp(r'^\s*(error|warning|info|hint)\s*-\s*([^:]+):(\d+):(\d+)\s*-\s*(.+)\s*-\s*(.+)$').firstMatch(line);
      if (match != null) {
        final severity = match.group(1)!;
        final file = match.group(2)!;
        final lineNum = int.parse(match.group(3)!);
        final colNum = int.parse(match.group(4)!);
        final msg = match.group(5)!;
        final code = match.group(6)!;

        issues.add(VerificationIssue(
          severity: severity,
          origin: origin,
          file: file,
          range: Range(
            start: Position(line: lineNum, column: colNum),
            end: Position(line: lineNum, column: colNum + 5),
          ),
          code: code,
          message: msg,
          fixHint: 'Review code symbols or resolve: $code.',
        ));
      } else if (line.contains('failed') || line.contains('Error:')) {
        // Fallback simple match for compiler/test failure logs
        issues.add(VerificationIssue(
          severity: 'error',
          origin: origin,
          file: 'unknown_file',
          range: const Range(
            start: Position(line: 1, column: 1),
            end: Position(line: 1, column: 10),
          ),
          code: 'EXECUTION_FAILURE',
          message: line.trim(),
          fixHint: 'Inspect command trace details.',
        ));
      }
    }

    return issues;
  }
}
