import '../models/tool_execution_context.dart';

abstract class McpGateway {
  Future<Map<String, dynamic>> handleToolCall(String name,
      Map<String, dynamic> arguments, ToolExecutionContext context);
}
