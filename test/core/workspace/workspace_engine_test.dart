import 'package:test/test.dart';
import 'package:indiverse_developer_platform/core/events/event_bus.dart';
import 'package:indiverse_developer_platform/core/workspace/workspace_state.dart';
import 'package:indiverse_developer_platform/core/workspace/workspace_metadata.dart';
import 'package:indiverse_developer_platform/core/workspace/workspace.dart';
import 'package:indiverse_developer_platform/core/workspace/workspace_cache.dart';
import 'package:indiverse_developer_platform/core/workspace/workspace_diagnostics.dart';
import 'package:indiverse_developer_platform/core/workspace/workspace_manager.dart';
import 'package:indiverse_developer_platform/core/workspace/workspace_registry.dart';
import 'package:indiverse_developer_platform/core/workspace/discovery/detector_registry.dart';
import 'package:indiverse_developer_platform/core/workspace/discovery/flutter_detector.dart';
import 'package:indiverse_developer_platform/core/workspace/index/workspace_indexer.dart';
import 'package:indiverse_developer_platform/core/workspace/index/incremental_indexer.dart';
import 'package:indiverse_developer_platform/core/workspace/graph/dependency_graph.dart';
import 'package:indiverse_developer_platform/core/workspace/context/context_budget.dart';
import 'package:indiverse_developer_platform/core/workspace/context/context_builder.dart';
import 'package:indiverse_developer_platform/core/workspace/context/providers/readme_provider.dart';
import 'package:indiverse_developer_platform/core/workspace/context/providers/git_provider.dart';

void main() {
  group('Workspace Engine Tests', () {
    late EventBus eventBus;
    late WorkspaceRegistry registry;
    late WorkspaceCache cache;
    late DetectorRegistry detectorRegistry;
    late WorkspaceManager manager;

    setUp(() {
      eventBus = EventBus();
      registry = WorkspaceRegistry();
      cache = WorkspaceCache();
      detectorRegistry = DetectorRegistry();
      manager = WorkspaceManager(
        registry: registry,
        cache: cache,
        detectorRegistry: detectorRegistry,
        eventBus: eventBus,
      );
    });

    test('Workspace State transitions correctly during lifecycle', () async {
      expect(manager.state, equals(WorkspaceState.closed));

      final future = manager.openWorkspace("test_root");
      expect(manager.state, equals(WorkspaceState.opening));

      final workspace = await future;
      expect(manager.state, equals(WorkspaceState.ready));
      expect(registry.active, equals(workspace));

      await manager.closeWorkspace("test_root");
      expect(manager.state, equals(WorkspaceState.closed));
      expect(registry.active, isNull);
    });

    test('Detector registry runs extensible discovery pipeline', () async {
      detectorRegistry.register(FlutterDetector());
      final results = await detectorRegistry.runAll("test_root");
      expect(results.length, equals(1));
      expect(results.first.name, equals("flutter"));
      expect(results.first.isDetected,
          isFalse); // test_root does not have pubspec.yaml
    });

    test('Incremental indexer updates cached hashes and counts statistics',
        () async {
      final indexer = WorkspaceIndexer();
      final incremental = IncrementalIndexer(cache: cache, indexer: indexer);

      final stats =
          await incremental.indexChanges("test_root", ["pubspec.yaml"]);
      expect(cache.getFileHash("pubspec.yaml"), equals("mock-hash-value"));
      expect(stats.filesIndexed, isZero); // folder does not exist
    });

    test('DependencyGraph stores and fetches edges cleanly', () {
      final graph = DependencyGraph();
      graph.addEdge("A", "B");
      graph.addEdge("A", "C");

      expect(graph.getDependencies("A"), containsAll(["B", "C"]));
    });

    test('ContextBuilder ranks and prunes chunks based on Token Budget policy',
        () async {
      final builder = ContextBuilder(
        providers: [
          ReadmeProvider(),
          GitProvider(),
        ],
        policy: const TinyPolicy(),
      );

      final list = await builder.assemble("test_root");
      expect(list, isEmpty); // files do not exist in test_root
    });

    test('Diagnostics export summaries format properly', () {
      final metadata = WorkspaceMetadata(
        projectName: "IndiCabs",
        organization: "IndiVerse",
        primaryLanguage: "dart",
        architecture: "clean",
        rules: const ["rule1"],
        adrs: const ["adr1"],
        created: DateTime.now(),
        lastIndexed: DateTime.now(),
        platformVersion: "0.5.0",
      );

      final workspace = Workspace(
        id: "indicabs",
        name: "IndiCabs",
        rootPath: "indicabs",
        projectTypes: const ["flutter"],
        repositories: const [],
        configuration: const {},
        metadata: metadata,
      );

      final diag = WorkspaceDiagnostics(workspace);
      expect(diag.exportSummary(), contains("IndiCabs"));
      expect(diag.exportMarkdown(), contains("Detected Types"));
      expect(diag.exportJson(), contains("indicabs"));
    });
  });
}
