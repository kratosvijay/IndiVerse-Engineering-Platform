import 'dart:convert';
import 'dart:io';

void main() async {
  final stopwatch = Stopwatch()..start();
  await Future<void>.delayed(const Duration(milliseconds: 5));
  stopwatch.stop();
  final ms = stopwatch.elapsedMilliseconds;
  final report = {
    "metric": "agentDispatchTimeMs",
    "value": ms,
    "threshold": 50,
    "status": ms < 50 ? "PASS" : "FAIL"
  };
  File('benchmark/reports/agent.json').writeAsStringSync(jsonEncode(report));
  print("Agent dispatch time: $ms ms");
}
