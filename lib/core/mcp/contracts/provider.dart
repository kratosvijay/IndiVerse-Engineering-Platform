import '../models/mcp_tool.dart';
import '../models/mcp_resource.dart';
import '../models/mcp_prompt.dart';

abstract class ToolProvider {
  List<McpTool> getTools();
}

abstract class ResourceProvider {
  List<McpResource> getResources();
}

abstract class PromptProvider {
  List<McpPrompt> getPrompts();
}
