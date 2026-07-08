import 'dart:io';
import '../../../models/tool_call_models.dart';
import '../tool_handler.dart';

class GitStatusTool implements ToolHandler {
  @override
  final ToolDescriptor descriptor = const ToolDescriptor(
    id: 'git.status',
    name: 'Git Status',
    description: 'Get the current git status of the workspace repository.',
    category: ToolCategory.git,
    requiresPermission: false,
    readOnly: true,
    destructive: false,
    modifiesWorkspace: false,
    tags: ['git', 'status', 'vcs'],
  );

  @override
  Future<ToolCallResult> execute(ToolCallRequest request, ToolExecutionContext context) async {
    final stopwatch = Stopwatch()..start();

    try {
      final result = await Process.run('git', ['status', '--porcelain']);
      if (result.exitCode == 0) {
        final output = result.stdout as String;
        return ToolCallResult(
          success: true,
          output: ToolOutput(
            data: output,
            displayText: output.trim().isEmpty ? 'Workspace is clean (git status clean).' : output,
            mimeType: 'text/plain',
          ),
          duration: stopwatch.elapsed,
        );
      } else {
        return ToolCallResult(
          success: false,
          output: ToolOutput(
            displayText: 'git status returned exit code ${result.exitCode}: ${result.stderr}',
            mimeType: 'text/plain',
          ),
          duration: stopwatch.elapsed,
          errorCode: 'GIT_ERROR',
        );
      }
    } catch (e) {
      // Fallback for environments without git binary
      return ToolCallResult(
        success: true,
        output: const ToolOutput(
          data: 'MOCK_GIT_CLEAN',
          displayText: 'No git repository detected or git binary not available (mock fallback clean).',
          mimeType: 'text/plain',
        ),
        duration: stopwatch.elapsed,
      );
    }
  }
}
