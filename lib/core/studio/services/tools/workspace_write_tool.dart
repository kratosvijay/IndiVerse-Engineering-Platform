import 'dart:io';
import '../../../models/tool_call_models.dart';
import '../tool_handler.dart';
import '../workspace_service.dart';

class WorkspaceWriteTool implements ToolHandler {
  @override
  final ToolDescriptor descriptor = const ToolDescriptor(
    id: 'workspace.writeFile',
    name: 'Write File',
    description:
        'Write content to a file in the workspace, creating it if it does not exist.',
    category: ToolCategory.filesystem,
    requiresPermission: true,
    readOnly: false,
    destructive: false,
    modifiesWorkspace: true,
    tags: ['write', 'create', 'file'],
  );

  @override
  Future<ToolCallResult> execute(
      ToolCallRequest request, ToolExecutionContext context) async {
    final stopwatch = Stopwatch()..start();
    final path = request.arguments['path'] as String? ??
        request.arguments['filePath'] as String? ??
        '';
    final content = request.arguments['content'] as String? ?? '';

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
      final file = File('${Directory.current.path}/$path');
      final exists = file.existsSync();

      if (exists) {
        await workspaceService.saveFile(path, content);
      } else {
        await workspaceService.createFile(path, content);
      }

      return ToolCallResult(
        success: true,
        output: ToolOutput(
          displayText: 'Successfully wrote content to "$path".',
          mimeType: 'text/plain',
        ),
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      return ToolCallResult(
        success: false,
        output: ToolOutput(
          displayText: 'Failed to write file: $e',
          mimeType: 'text/plain',
        ),
        duration: stopwatch.elapsed,
        errorCode: 'WRITE_FAILED',
      );
    }
  }
}
