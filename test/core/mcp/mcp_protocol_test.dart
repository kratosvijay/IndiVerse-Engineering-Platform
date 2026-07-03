import 'package:test/test.dart';
import 'package:indiverse_developer_platform/core/mcp/registry/tool_registry.dart';
import 'package:indiverse_developer_platform/core/mcp/providers/tool_provider.dart';
import 'package:indiverse_developer_platform/core/mcp/gateway/mcp_gateway.dart';
import 'package:indiverse_developer_platform/core/mcp/gateway/authorization_service.dart';
import 'package:indiverse_developer_platform/core/mcp/models/tool_execution_context.dart';
import 'package:indiverse_developer_platform/core/mcp/models/session_context.dart';
import 'package:indiverse_developer_platform/core/mcp/models/request_context.dart';
import 'package:indiverse_developer_platform/core/mcp/models/permission.dart';
import 'package:indiverse_developer_platform/platform_sdk/platform_sdk.dart';
import 'package:indiverse_developer_platform/platform_sdk/runtime_api.dart';
import 'package:indiverse_developer_platform/platform_sdk/workspace_api.dart';
import 'package:indiverse_developer_platform/platform_sdk/knowledge_api.dart';
import 'package:indiverse_developer_platform/platform_sdk/agent_api.dart';
import 'package:indiverse_developer_platform/platform_sdk/plugin_api.dart';

void main() {
  group('MCP Protocol Tests', () {
    test('Verify tool registration and authorized query dispatching', () async {
      final registry = ToolRegistry();
      final provider = SystemToolProvider();
      for (final tool in provider.getTools()) {
        registry.register(tool);
      }

      final gateway = McpGatewayImpl(registry, AuthorizationService());
      final sdk = PlatformSDK(
        runtime: RuntimeAPI(),
        workspace: WorkspaceAPI(),
        knowledge: KnowledgeAPI(),
        agent: AgentAPI(),
        plugin: PluginAPI(),
      );

      final context = ToolExecutionContext(
        session: const SessionContext(
          sessionId: 'session-1',
          protocolVersion: '1.0',
          permissions: [Permission.knowledgeSearch],
        ),
        request:
            const RequestContext(requestId: 'request-1', isCancelled: false),
        sdk: sdk,
      );

      final result = await gateway.handleToolCall('search', {}, context);
      expect(result['status'], equals('success'));
    });
  });
}
