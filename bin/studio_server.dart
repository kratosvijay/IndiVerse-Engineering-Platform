import 'package:indiverse_developer_platform/core/studio/server/server.dart';
import 'package:indiverse_developer_platform/platform_sdk/platform_sdk.dart';
import 'package:indiverse_developer_platform/platform_sdk/runtime_api.dart';
import 'package:indiverse_developer_platform/platform_sdk/workspace_api.dart';
import 'package:indiverse_developer_platform/platform_sdk/knowledge_api.dart';
import 'package:indiverse_developer_platform/platform_sdk/agent_api.dart';
import 'package:indiverse_developer_platform/platform_sdk/plugin_api.dart';

void main() async {
  final sdk = PlatformSDK(
    runtime: RuntimeAPI(),
    workspace: WorkspaceAPI(),
    knowledge: KnowledgeAPI(),
    agent: AgentAPI(),
    plugin: PluginAPI(),
  );

  final server = StudioServer(sdk);
  final port = await server.start(preferredPort: 18080);
  print('==================================================');
  print(' IndiVerse Studio Server Running on port: $port');
  print(' Health check: http://localhost:$port/api/health');
  print(' WS events stream: ws://localhost:$port/ws/events');
  print('==================================================');
}
