import 'dart:convert';
import 'dart:io';
import 'package:indiverse_developer_platform/core/events/event_bus.dart';
import 'package:indiverse_developer_platform/core/workspace/workspace_registry.dart';
import 'package:indiverse_developer_platform/core/workspace/workspace_cache.dart';
import 'package:indiverse_developer_platform/core/workspace/discovery/detector_registry.dart';
import 'package:indiverse_developer_platform/core/workspace/workspace_manager.dart';

void main() async {
  final stopwatch = Stopwatch()..start();
  final manager = WorkspaceManager(
    registry: WorkspaceRegistry(),
    cache: WorkspaceCache(),
    detectorRegistry: DetectorRegistry(),
    eventBus: EventBus(),
  );
  await manager.openWorkspace(Directory.current.path);
  stopwatch.stop();
  final ms = stopwatch.elapsedMilliseconds;
  final report = {
    "metric": "workspaceScanTimeMs",
    "value": ms,
    "threshold": 500,
    "status": ms < 500 ? "PASS" : "FAIL"
  };
  File('benchmark/reports/workspace.json')
      .writeAsStringSync(jsonEncode(report));
  print("Workspace discovery time: $ms ms");
}
