import '../../../models/tool_call_models.dart';
import '../tool_handler.dart';
import '../search_service.dart';

class WorkspaceSearchTool implements ToolHandler {
  @override
  final ToolDescriptor descriptor = const ToolDescriptor(
    id: 'workspace.search',
    name: 'Search Workspace',
    description: 'Search for symbols or keywords in the workspace.',
    category: ToolCategory.workspace,
    requiresPermission: false,
    readOnly: true,
    destructive: false,
    modifiesWorkspace: false,
    tags: ['search', 'workspace', 'symbols'],
  );

  @override
  Future<ToolCallResult> execute(
      ToolCallRequest request, ToolExecutionContext context) async {
    final stopwatch = Stopwatch()..start();
    final query = request.arguments['query'] as String? ??
        request.arguments['q'] as String? ??
        '';
    final mode = request.arguments['mode'] as String? ?? 'symbol';
    final page = request.arguments['page'] as int? ?? 1;
    final pageSize = request.arguments['pageSize'] as int? ?? 20;

    if (query.isEmpty) {
      return ToolCallResult(
        success: false,
        output: const ToolOutput(
          displayText: 'Search query is empty.',
          mimeType: 'text/plain',
        ),
        duration: stopwatch.elapsed,
        errorCode: 'EMPTY_QUERY',
      );
    }

    try {
      final searchService = SearchService(context.sdk);
      final results = await searchService.searchCodebase(
        query: query,
        mode: mode,
        page: page,
        pageSize: pageSize,
      );

      return ToolCallResult(
        success: true,
        output: ToolOutput(
          data: results,
          displayText: 'Found ${results.length} matches for "$query".',
          mimeType: 'application/json',
        ),
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      return ToolCallResult(
        success: false,
        output: ToolOutput(
          displayText: 'Failed to search codebase: $e',
          mimeType: 'text/plain',
        ),
        duration: stopwatch.elapsed,
        errorCode: 'SEARCH_FAILED',
      );
    }
  }
}
