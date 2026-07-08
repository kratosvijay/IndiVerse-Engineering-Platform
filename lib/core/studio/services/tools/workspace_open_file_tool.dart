import '../../../models/tool_call_models.dart';
import '../tool_handler.dart';
import '../workspace_service.dart';

class WorkspaceOpenFileTool implements ToolHandler {
  @override
  final ToolDescriptor descriptor = const ToolDescriptor(
    id: 'workspace.openFile',
    name: 'Open File',
    description: 'Retrieve stats, symbols, and metadata for a file in the workspace.',
    category: ToolCategory.workspace,
    requiresPermission: false,
    readOnly: true,
    destructive: false,
    modifiesWorkspace: false,
    tags: ['open', 'file', 'metadata'],
  );

  @override
  Future<ToolCallResult> execute(ToolCallRequest request, ToolExecutionContext context) async {
    final stopwatch = Stopwatch()..start();
    final path = request.arguments['path'] as String? ?? request.arguments['filePath'] as String? ?? '';

    if (path.isEmpty) {
      return ToolCallResult(
        success: false,
        output: const ToolOutput(
          displayText: 'File path is empty.',
          mimeType: 'text/plain',
        ),
        duration: stopwatch.elapsed,
        errorCode: 'EMPTY_PATH',
      );
    }

    try {
      final workspaceService = WorkspaceService(context.sdk);
      final stat = await workspaceService.getStat(path);

      return ToolCallResult(
        success: true,
        output: ToolOutput(
          data: stat,
          displayText: 'Successfully opened file metadata for "$path".',
          mimeType: 'application/json',
        ),
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      return ToolCallResult(
        success: false,
        output: ToolOutput(
          displayText: 'Failed to open file: $e',
          mimeType: 'text/plain',
        ),
        duration: stopwatch.elapsed,
        errorCode: 'OPEN_FAILED',
      );
    }
  }
}
