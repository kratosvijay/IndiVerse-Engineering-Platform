import 'tool_manifest.dart';
import 'tool_execution_context.dart';

class McpTool {
  final ToolManifest manifest;
  final Future<Map<String, dynamic>> Function(
      Map<String, dynamic> arguments, ToolExecutionContext context) execute;

  const McpTool({
    required this.manifest,
    required this.execute,
  });
}
