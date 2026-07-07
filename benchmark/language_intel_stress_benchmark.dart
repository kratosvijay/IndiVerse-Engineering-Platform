import 'dart:convert';
import 'dart:io';
import 'package:indiverse_developer_platform/core/diagnostics/diagnostic_models.dart';
import 'package:indiverse_developer_platform/core/code_actions/code_action_provider.dart';

void main() async {
  print(
      "=== Sprint 20 Language Intelligence Performance Stress Benchmarks ===");

  // 1. Generate large file documents in-memory
  final Map<String, String> files = {
    "1k": "void main() {\n" +
        List.generate(1000, (i) => "  var x$i = $i; // TODO: complete $i")
            .join("\n") +
        "\n}",
    "10k": "void main() {\n" +
        List.generate(10000, (i) => "  var x$i = $i; // TODO: complete $i")
            .join("\n") +
        "\n}",
    "50k": "void main() {\n" +
        List.generate(50000, (i) => "  var x$i = $i; // TODO: complete $i")
            .join("\n") +
        "\n}",
    "100k": "void main() {\n" +
        List.generate(100000, (i) => "  var x$i = $i; // TODO: complete $i")
            .join("\n") +
        "\n}",
  };

  final codeActionProvider = CodeActionProvider();
  final reports = <Map<String, dynamic>>[];

  for (final entry in files.entries) {
    final size = entry.key;
    final content = entry.value;

    final doc = DocumentSnapshot(
      path: 'lib/large_$size.dart',
      content: content,
      revision: 1,
    );

    // Measure Diagnostics resolution
    final diagStopwatch = Stopwatch()..start();
    final diagnostics = <Diagnostic>[];
    final lines = content.split('\n');
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.contains('TODO')) {
        diagnostics.add(Diagnostic(
          id: 'todo-$i',
          message: 'TODO found',
          severity: DiagnosticSeverity.information,
          range: Range(
            start: Position(line: i + 1, column: 1),
            end: Position(line: i + 1, column: line.length + 1),
          ),
          code: 'todo',
          source: 'large-file-benchmark',
        ));
      }
    }
    diagStopwatch.stop();
    final diagMs = diagStopwatch.elapsedMilliseconds;

    // Measure Code Actions resolution
    final actionStopwatch = Stopwatch()..start();
    final selection = const Range(
      start: Position(line: 5, column: 1),
      end: Position(line: 5, column: 10),
    );
    final actions =
        codeActionProvider.getCodeActions(doc, selection, diagnostics);
    actionStopwatch.stop();
    final actionMs = actionStopwatch.elapsedMilliseconds;

    print(
        "File size: $size lines | Diagnostics Parse: $diagMs ms | Code Actions Resolve: $actionMs ms | Total Actions Found: ${actions.length}");

    reports.add({
      "fileSizeLines": size,
      "diagnosticsParseMs": diagMs,
      "codeActionsResolveMs": actionMs,
      "totalActionsFound": actions.length,
    });
  }

  // Save the report
  final reportFile = File('benchmark/reports/performance_report.json');
  reportFile.parent.createSync(recursive: true);
  reportFile.writeAsStringSync(jsonEncode({
    "timestamp": DateTime.now().toIso8601String(),
    "benchmarks": reports,
  }));
  print("Saved benchmark report to: benchmark/reports/performance_report.json");
}
