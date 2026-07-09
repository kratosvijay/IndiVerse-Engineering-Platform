import 'dart:async';
import 'dart:io';
import 'workspace_intelligence.dart';
import 'workspace.dart';
import 'workspace_state.dart';
import 'workspace_registry.dart';
import 'workspace_cache.dart';
import 'workspace_metadata.dart';
import 'discovery/detector_registry.dart';
import 'events/workspace_event.dart';
import '../events/event_bus.dart';

class WorkspaceManager {
  final WorkspaceRegistry registry;
  final WorkspaceCache cache;
  final DetectorRegistry detectorRegistry;
  final EventBus eventBus;

  WorkspaceState _state = WorkspaceState.closed;

  WorkspaceManager({
    required this.registry,
    required this.cache,
    required this.detectorRegistry,
    required this.eventBus,
  });

  WorkspaceState get state => _state;

  Future<Workspace> openWorkspace(String rootPath) async {
    _state = WorkspaceState.opening;

    await _initializeIntelligence(rootPath);

    final cached = await cache.load(rootPath);
    if (cached != null) {
      registry.setActive(cached);
      _state = WorkspaceState.ready;
      eventBus.publish(WorkspaceReady(
        timestamp: DateTime.now(),
        eventId: "ready-${DateTime.now().millisecondsSinceEpoch}",
        rootPath: rootPath,
      ));
      return cached;
    }

    _state = WorkspaceState.discovering;
    final results = await detectorRegistry.runAll(rootPath);
    final types =
        results.where((r) => r.isDetected).map((r) => r.name).toList();

    _state = WorkspaceState.indexing;

    final metadata = WorkspaceMetadata(
      projectName: rootPath.split('/').last,
      organization: "IndiVerse",
      primaryLanguage: types.contains("dart") ? "dart" : "unknown",
      architecture: "clean",
      rules: const [],
      adrs: const [],
      created: DateTime.now(),
      lastIndexed: DateTime.now(),
      platformVersion: "0.5.0",
    );

    final workspace = Workspace(
      id: rootPath.split('/').last,
      name: rootPath.split('/').last,
      rootPath: rootPath,
      projectTypes: types,
      repositories: const [],
      configuration: const {},
      metadata: metadata,
    );

    await cache.save(rootPath, workspace);
    registry.setActive(workspace);
    _state = WorkspaceState.ready;

    eventBus.publish(WorkspaceOpened(
      timestamp: DateTime.now(),
      eventId: "opened-${DateTime.now().millisecondsSinceEpoch}",
      rootPath: rootPath,
    ));

    return workspace;
  }

  Future<void> closeWorkspace(String rootPath) async {
    _state = WorkspaceState.closing;
    registry.clearActive();
    WorkspaceIntelligenceRegistry.clearActive();
    _state = WorkspaceState.closed;

    eventBus.publish(WorkspaceClosed(
      timestamp: DateTime.now(),
      eventId: "closed-${DateTime.now().millisecondsSinceEpoch}",
      rootPath: rootPath,
    ));
  }

  Future<void> _initializeIntelligence(String rootPath) async {
    final intel = WorkspaceIntelligence(
      workspaceId: rootPath.split('/').last,
      workspacePath: rootPath,
    );
    WorkspaceIntelligenceRegistry.register(rootPath, intel);
    WorkspaceIntelligenceRegistry.setActive(rootPath);

    final dir = Directory(rootPath);
    if (await dir.exists()) {
      await for (final entity
          in dir.list(recursive: true, followLinks: false)) {
        if (entity is File && entity.path.endsWith('.dart')) {
          try {
            final content = await entity.readAsString();
            intel.indexFile(entity.path, content);
          } catch (_) {}
        }
      }
    }
  }
}
