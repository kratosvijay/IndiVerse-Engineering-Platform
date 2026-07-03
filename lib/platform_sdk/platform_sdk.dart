import 'runtime_api.dart';
import 'workspace_api.dart';
import 'knowledge_api.dart';
import 'agent_api.dart';
import 'plugin_api.dart';

class PlatformSDK {
  final RuntimeAPI runtime;
  final WorkspaceAPI workspace;
  final KnowledgeAPI knowledge;
  final AgentAPI agent;
  final PluginAPI plugin;

  const PlatformSDK({
    required this.runtime,
    required this.workspace,
    required this.knowledge,
    required this.agent,
    required this.plugin,
  });
}
