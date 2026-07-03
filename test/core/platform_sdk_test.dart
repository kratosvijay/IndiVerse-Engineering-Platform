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
    });
  });
}
