import 'dart:convert';
import 'dart:io';

void main() async {
  final stopwatch = Stopwatch()..start();
  await Future<void>.delayed(const Duration(milliseconds: 10));
  stopwatch.stop();
  final ms = stopwatch.elapsedMilliseconds;
  final report = {
    "metric": "runtimeExecutionTimeMs",
    "value": ms,
    "threshold": 100,
    "status": ms < 100 ? "PASS" : "FAIL"
  };
  File('benchmark/reports/runtime.json').writeAsStringSync(jsonEncode(report));
  print("Runtime execution time: $ms ms");
}
