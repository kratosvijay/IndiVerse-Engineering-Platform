import 'package:test/test.dart';
import 'package:indiverse_developer_platform/core/events/event_bus.dart';
import 'package:indiverse_developer_platform/core/security/credential_manager.dart';
import 'package:indiverse_developer_platform/core/runtime/runtime.dart';
import 'package:indiverse_developer_platform/core/integrations/integration.dart';
import 'package:indiverse_developer_platform/core/integrations/registry.dart';
import 'package:indiverse_developer_platform/core/integrations/plugin_manager.dart';
import 'package:indiverse_developer_platform/core/integrations/dependency_graph.dart';
import 'package:indiverse_developer_platform/core/integrations/capability.dart';
import 'package:indiverse_developer_platform/core/integrations/plugins/builtin/gemini/gemini_plugin.dart';
import 'package:indiverse_developer_platform/sdk/public/plugin_sdk.dart';
import 'dart:async';

void main() {
  group('Integration & Plugin Platform Tests', () {
    late EventBus eventBus;
    late CredentialManager credentialManager;
    late Runtime runtime;
    late IntegrationRegistry registry;
    late PluginContext context;
    late PluginManager manager;

    setUp(() {
      eventBus = EventBus();
      credentialManager = CredentialManager();
      runtime = Runtime(eventBus: eventBus);
      registry = IntegrationRegistry();
      context = PluginContext(
        pluginId: "test-env",
        correlationId: "test-correlation-id",
        logger: PluginLogger("test-env"),
        storage: MemoryPluginStorage(),
        configuration: const PluginConfiguration(),
        eventBus: eventBus,
        credentialManager: credentialManager,
        runtime: runtime,
        workspace: const WorkspaceInfo(
          project: "test-proj",
          repository: "test-repo",
          branch: "main",
          environment: "local",
        ),
        cancellationToken: Completer<void>(),
      );
      manager = PluginManager(registry: registry, context: context);
    });

    test('should register and activate built-in gemini plugin successfully',
        () async {
      final plugin = GeminiPlugin(context);
      final success = await manager.registerAndActivate(plugin);

      expect(success, isTrue);
      expect(manager.getPluginState("gemini"), PluginState.activated);

      final best = registry.findBest(IntegrationCapability.aiChat);
      expect(best, isNotNull);
      expect(best!.manifest.id, equals("gemini"));

      final result = await plugin.executeCommand("generate", {});
      expect(result["text"], equals("Gemini response"));
    });

    test('should build and sort dependency graph topological order cleanly',
        () {
      final graph = DependencyGraph();
      graph.addNode("openhands", ["python", "docker"]);
      graph.addNode("python", []);
      graph.addNode("docker", []);

      final order = graph.getResolveOrder();
      expect(order.indexOf("openhands") > order.indexOf("python"), isTrue);
      expect(order.indexOf("openhands") > order.indexOf("docker"), isTrue);
    });
  });
}
