import 'dart:convert';
import 'dart:io';
import 'package:indiverse_developer_platform/platform_sdk/platform_sdk.dart';
import 'package:indiverse_developer_platform/platform_sdk/runtime_api.dart';
import 'package:indiverse_developer_platform/platform_sdk/workspace_api.dart';
import 'package:indiverse_developer_platform/platform_sdk/knowledge_api.dart';
import 'package:indiverse_developer_platform/platform_sdk/agent_api.dart';
import 'package:indiverse_developer_platform/platform_sdk/plugin_api.dart';

void main() async {
  final stopwatch = Stopwatch()..start();
  final sdk = PlatformSDK(
    runtime: RuntimeAPI(),
    workspace: WorkspaceAPI(),
    knowledge: KnowledgeAPI(),
    agent: AgentAPI(),
    plugin: PluginAPI(),
  );
  await sdk.health.checkHealth();
  stopwatch.stop();
  final ms = stopwatch.elapsedMilliseconds;
  final report = {
    "metric": "startupTimeMs",
    "value": ms,
    "threshold": 150,
    "status": ms < 150 ? "PASS" : "FAIL"
  };
  File('benchmark/reports/startup.json').writeAsStringSync(jsonEncode(report));
  print("Startup time: $ms ms");
}
