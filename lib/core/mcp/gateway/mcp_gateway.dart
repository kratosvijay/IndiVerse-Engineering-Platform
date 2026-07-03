import '../contracts/gateway.dart';
import '../models/tool_execution_context.dart';
import '../registry/tool_registry.dart';
import 'authorization_service.dart';

class McpGatewayImpl implements McpGateway {
  final ToolRegistry registry;
  final AuthorizationService auth;

  McpGatewayImpl(this.registry, this.auth);

  @override
  Future<Map<String, dynamic>> handleToolCall(
    String name,
    Map<String, dynamic> arguments,
    ToolExecutionContext context,
  ) async {
    final tool = registry.get(name);
    if (tool == null) {
      throw Exception("Tool $name not found");
    }
    final authorized = await auth.authorize(
      context.session.permissions,
      tool.manifest.permissions,
    );
    if (!authorized) {
      throw Exception("Unauthorized tool call");
    }
    return await tool.execute(arguments, context);
  }
}
