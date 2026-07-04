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
  group('Studio Versioned Controllers and Services Tests', () {
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
      port = await server.start(preferredPort: 18090);
    });

    tearDown(() async {
      await server.stop();
    });

    test('Verify versioned v1 REST API routing with standard envelopes',
        () async {
      final workspaceUri = Uri.parse('http://localhost:$port/api/v1/workspace');
      final res = await http.get(workspaceUri);
      expect(res.statusCode, equals(200));

      final json = jsonDecode(res.body);
      expect(json["success"], isTrue);
      expect(json["version"], equals("1.0.1"));
      expect(json["requestId"], startsWith("req-"));
      expect(json["data"]["activeProject"],
          equals("indiverse-engineering-platform"));
      expect(json["data"]["files"], isNotEmpty);
    });

    test('Verify versioned v1 search service with line-matching snippets',
        () async {
      final searchUri = Uri.parse(
          'http://localhost:$port/api/v1/search?q=PlatformSDK&mode=symbol');
      final res = await http.get(searchUri);
      expect(res.statusCode, equals(200));

      final json = jsonDecode(res.body);
      expect(json["success"], isTrue);
      expect(json["data"]["results"], isNotEmpty);
      expect(json["data"]["results"][0]["filePath"], isNotEmpty);
      expect(json["data"]["results"][0]["snippet"], contains("PlatformSDK"));
    });

    test('Verify generic Inspector endpoint results', () async {
      final inspectorUri = Uri.parse(
          'http://localhost:$port/api/v1/inspector?id=lib/core/studio/server/server.dart&type=workspace');
      final res = await http.get(inspectorUri);
      expect(res.statusCode, equals(200));

      final json = jsonDecode(res.body);
      expect(json["success"], isTrue);
      expect(json["data"]["type"], equals("workspace"));
      expect(json["data"]["details"]["language"], equals("Dart"));
    });

    test('Verify Architecture topology and node details mapping', () async {
      final topoUri = Uri.parse('http://localhost:$port/api/v1/architecture');
      final res1 = await http.get(topoUri);
      expect(res1.statusCode, equals(200));
      final json1 = jsonDecode(res1.body);
      expect(json1["data"]["nodes"], isNotEmpty);

      final nodeUri = Uri.parse(
          'http://localhost:$port/api/v1/architecture/node?id=knowledge');
      final res2 = await http.get(nodeUri);
      expect(res2.statusCode, equals(200));
      final json2 = jsonDecode(res2.body);
      expect(json2["data"]["name"], equals("Knowledge Engine"));
      expect(json2["data"]["health"], equals("Healthy"));
    });

    test('Verify agent workflow pipeline controls', () async {
      final runUri = Uri.parse('http://localhost:$port/api/v1/agent/run');
      final res1 =
          await http.post(runUri, body: jsonEncode({"name": "Planner"}));
      expect(res1.statusCode, equals(200));
      final json1 = jsonDecode(res1.body);
      expect(json1["data"]["status"], equals("running"));
      final workflowId = json1["data"]["workflowId"];

      final statusUri = Uri.parse('http://localhost:$port/api/v1/agent/status');
      final res2 = await http.get(statusUri);
      expect(res2.statusCode, equals(200));
      final json2 = jsonDecode(res2.body);
      expect(json2["data"]["status"], equals("running"));

      final cancelUri = Uri.parse('http://localhost:$port/api/v1/agent/cancel');
      final res3 = await http.post(cancelUri,
          body: jsonEncode({"workflowId": workflowId}));
      expect(res3.statusCode, equals(200));
    });

    test('Verify server CRUD workspace file REST APIs', () async {
      // 1. Create a test file
      final createUri = Uri.parse(
          'http://localhost:$port/api/v1/workspace/file?path=test_temp.txt');
      final res1 = await http.post(
        createUri,
        body: jsonEncode({"content": "hello integration"}),
      );
      expect(res1.statusCode, equals(200));
      expect(jsonDecode(res1.body)["success"], isTrue);

      // 2. Read back contents to verify
      final readUri = Uri.parse(
          'http://localhost:$port/api/v1/workspace/file?path=test_temp.txt');
      final res2 = await http.get(readUri);
      expect(res2.statusCode, equals(200));
      expect(jsonDecode(res2.body)["data"]["content"],
          equals("hello integration"));

      // 3. Save updates to it
      final saveUri = Uri.parse(
          'http://localhost:$port/api/v1/workspace/file?path=test_temp.txt');
      final res3 = await http.put(
        saveUri,
        body: jsonEncode({"content": "hello integration saved"}),
      );
      expect(res3.statusCode, equals(200));
      expect(jsonDecode(res3.body)["success"], isTrue);

      // 4. Rename
      final renameUri =
          Uri.parse('http://localhost:$port/api/v1/workspace/rename');
      final res4 = await http.post(
        renameUri,
        body: jsonEncode({
          "path": "test_temp.txt",
          "newPath": "test_temp_renamed.txt",
        }),
      );
      expect(res4.statusCode, equals(200));
      expect(jsonDecode(res4.body)["success"], isTrue);

      // 5. Delete
      final deleteUri = Uri.parse(
          'http://localhost:$port/api/v1/workspace/file?path=test_temp_renamed.txt');
      final res5 = await http.delete(deleteUri);
      expect(res5.statusCode, equals(200));
      expect(jsonDecode(res5.body)["success"], isTrue);
    });
  });
}
