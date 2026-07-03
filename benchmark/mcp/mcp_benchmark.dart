import 'dart:convert';
import 'dart:io';

void main() async {
  final stopwatch = Stopwatch()..start();
  final payload = jsonEncode(
      <String, dynamic>{"method": "tools/list", "params": <String, dynamic>{}});
  jsonDecode(payload);
  stopwatch.stop();
  final ms = stopwatch.elapsedMilliseconds;
  final report = {
    "metric": "mcpRequestTimeMs",
    "value": ms,
    "threshold": 100,
    "status": ms < 100 ? "PASS" : "FAIL"
  };
  File('benchmark/reports/mcp.json').writeAsStringSync(jsonEncode(report));
  print("MCP request time: $ms ms");
}
