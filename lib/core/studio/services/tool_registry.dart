import 'tool_handler.dart';
import '../../models/tool_call_models.dart';

class ToolRegistry {
  final Map<String, ToolHandler> _tools = {};

  void register(ToolHandler tool) {
    _tools[tool.descriptor.id] = tool;
  }

  void unregister(String id) {
    _tools.remove(id);
  }

  ToolHandler? getTool(String id) {
    return _tools[id];
  }

  List<ToolHandler> listTools() {
    return _tools.values.toList();
  }

  List<ToolHandler> filterByCategory(ToolCategory category) {
    return _tools.values.where((t) => t.descriptor.category == category).toList();
  }
}
