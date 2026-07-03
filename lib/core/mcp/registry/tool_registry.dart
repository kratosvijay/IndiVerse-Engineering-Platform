import '../models/mcp_tool.dart';

class ToolRegistry {
  final Map<String, McpTool> _tools = {};

  void register(McpTool tool) {
    _tools[tool.manifest.id] = tool;
  }

  McpTool? get(String id) => _tools[id];
  List<McpTool> list() => _tools.values.toList();
}
