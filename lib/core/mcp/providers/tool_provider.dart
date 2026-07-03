import '../contracts/provider.dart';
import '../models/mcp_tool.dart';
import '../models/tool_manifest.dart';
import '../models/permission.dart';

class SystemToolProvider implements ToolProvider {
  @override
  List<McpTool> getTools() {
    return [
      McpTool(
        manifest: const ToolManifest(
          id: 'search',
          version: '1.0.0',
          description: 'Semantic search tool.',
          permissions: [Permission.knowledgeSearch],
          estimatedCost: 0.0,
          timeout: Duration(seconds: 10),
        ),
        execute: (args, context) async {
          await context.sdk.knowledge.search();
          return {"status": "success", "results": <dynamic>[]};
        },
      )
    ];
  }
}
