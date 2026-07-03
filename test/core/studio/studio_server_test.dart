import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';
import 'package:indiverse_developer_platform/core/studio/server/server.dart';
import 'package:indiverse_developer_platform/platform_sdk/platform_sdk.dart';
import 'package:indiverse_developer_platform/platform_sdk/runtime_api.dart';
import 'package:indiverse_developer_platform/platform_sdk/workspace_api.dart';
import 'package:indiverse_developer_platform/platform_sdk/knowledge_api.dart';
import 'package:indiverse_developer_platform/platform_sdk/agent_api.dart';
import 'package:indiverse_developer_platform/platform_sdk/plugin_api.dart';

void main() {
  group('StudioServer Tests', () {
    late StudioServer server;
    late int port;

    setUp(() async {
      final sdk = PlatformSDK(
        runtime: RuntimeAPI(),
        workspace: WorkspaceAPI(),
        knowledge: KnowledgeAPI(),
        agent: AgentAPI(),
        plugin: PluginAPI(),
      );
      server = StudioServer(sdk);
      port = await server.start(preferredPort: 18080);
    });

    tearDown(() async {
      await server.stop();
    });

    test('Verify REST health, features and metrics endpoints', () async {
      final healthUri = Uri.parse('http://localhost:$port/api/health');
      final healthRes = await http.get(healthUri);
      expect(healthRes.statusCode, equals(200));
      final healthJson = jsonDecode(healthRes.body);
      expect(healthJson["Runtime"], equals("healthy"));

      final featuresUri = Uri.parse('http://localhost:$port/api/features');
      final featuresRes = await http.get(featuresUri);
      expect(featuresRes.statusCode, equals(200));
      final featuresJson = jsonDecode(featuresRes.body);
      expect(featuresJson["KnowledgeSearch"], isTrue);

      final metricsUri = Uri.parse('http://localhost:$port/api/metrics');
      final metricsRes = await http.get(metricsUri);
      expect(metricsRes.statusCode, equals(200));
      final metricsJson = jsonDecode(metricsRes.body);
      expect(metricsJson["workspaceFilesCount"], equals(0));
    });
  });
}
