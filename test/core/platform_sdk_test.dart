import 'package:test/test.dart';
import 'package:indiverse_developer_platform/platform_sdk/platform_sdk.dart';
import 'package:indiverse_developer_platform/platform_sdk/runtime_api.dart';
import 'package:indiverse_developer_platform/platform_sdk/workspace_api.dart';
import 'package:indiverse_developer_platform/platform_sdk/knowledge_api.dart';
import 'package:indiverse_developer_platform/platform_sdk/agent_api.dart';
import 'package:indiverse_developer_platform/platform_sdk/plugin_api.dart';

void main() {
  group('PlatformSDK Tests', () {
    test('Verify facade layer initialization', () {
      final sdk = PlatformSDK(
        runtime: RuntimeAPI(),
        workspace: WorkspaceAPI(),
        knowledge: KnowledgeAPI(),
        agent: AgentAPI(),
        plugin: PluginAPI(),
      );

      expect(sdk.runtime, isNotNull);
      expect(sdk.workspace, isNotNull);
      expect(sdk.knowledge, isNotNull);
      expect(sdk.agent, isNotNull);
      expect(sdk.plugin, isNotNull);
      expect(sdk.capabilities.runtime, isTrue);
      expect(sdk.versions.runtime, equals("v1"));
      expect(sdk.featureFlags.isEnabled("KnowledgeSearch"), isTrue);
      expect(sdk.featureFlags.isEnabled("MCP"), isFalse);
    });

    test('Verify health and metrics resolution', () async {
      final sdk = PlatformSDK(
        runtime: RuntimeAPI(),
        workspace: WorkspaceAPI(),
        knowledge: KnowledgeAPI(),
        agent: AgentAPI(),
        plugin: PluginAPI(),
      );

      final health = await sdk.health.checkHealth();
      expect(health["Runtime"], equals("healthy"));

      final metrics = await sdk.metrics.fetchMetrics();
      expect(metrics["workspaceFilesCount"], equals(0));
    });
  });
}
