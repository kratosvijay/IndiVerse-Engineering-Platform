abstract class McpMiddleware {
  Future<Map<String, dynamic>> handle(Map<String, dynamic> request,
      Future<Map<String, dynamic>> Function(Map<String, dynamic>) next);
}
