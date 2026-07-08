import '../../../models/tool_call_models.dart';
import '../tool_handler.dart';
import '../workspace_service.dart';

class WorkspaceReadTool implements ToolHandler {
  @override
  final ToolDescriptor descriptor = const ToolDescriptor(
    id: 'workspace.readFile',
    name: 'Read File',
    description: 'Read the contents of a file in the workspace.',
    category: ToolCategory.workspace,
    requiresPermission: false,
    readOnly: true,
    destructive: false,
    modifiesWorkspace: false,
    tags: ['read', 'file', 'workspace'],
  );

  @override
  Future<ToolCallResult> execute(
      ToolCallRequest request, ToolExecutionContext context) async {
    final stopwatch = Stopwatch()..start();
    final path = request.arguments['path'] as String? ??
        request.arguments['filePath'] as String? ??
        '';

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
      final data = await workspaceService.getFileContent(path);

      return ToolCallResult(
        success: true,
        output: ToolOutput(
          data: data,
          displayText: 'Successfully read file "$path".',
          mimeType: 'text/plain',
        ),
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      return ToolCallResult(
        success: false,
        output: ToolOutput(
          displayText: 'Failed to read file: $e',
          mimeType: 'text/plain',
        ),
        duration: stopwatch.elapsed,
        errorCode: 'READ_FAILED',
      );
    }
  }
}
