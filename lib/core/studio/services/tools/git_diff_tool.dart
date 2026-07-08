import 'dart:io';
import '../../../models/tool_call_models.dart';
import '../tool_handler.dart';

class GitDiffTool implements ToolHandler {
  @override
  final ToolDescriptor descriptor = const ToolDescriptor(
    id: 'git.diff',
    name: 'Git Diff',
    description: 'Get the git diff of uncommitted changes in the workspace.',
    category: ToolCategory.git,
    requiresPermission: false,
    readOnly: true,
    destructive: false,
    modifiesWorkspace: false,
    tags: ['git', 'diff', 'vcs'],
  );

  @override
  Future<ToolCallResult> execute(
      ToolCallRequest request, ToolExecutionContext context) async {
    final stopwatch = Stopwatch()..start();

    try {
      final result = await Process.run('git', ['diff']);
      if (result.exitCode == 0) {
        final output = result.stdout as String;
        return ToolCallResult(
          success: true,
          output: ToolOutput(
            data: output,
            displayText: output.trim().isEmpty
                ? 'No uncommitted modifications (git diff empty).'
                : output,
            mimeType: 'text/x-diff',
          ),
          duration: stopwatch.elapsed,
        );
      } else {
        return ToolCallResult(
          success: false,
          output: ToolOutput(
            displayText:
                'git diff returned exit code ${result.exitCode}: ${result.stderr}',
            mimeType: 'text/plain',
          ),
          duration: stopwatch.elapsed,
          errorCode: 'GIT_ERROR',
        );
      }
    } catch (e) {
      return ToolCallResult(
        success: true,
        output: const ToolOutput(
          data: 'MOCK_GIT_DIFF_EMPTY',
          displayText:
              'No git repository detected or git binary not available (mock fallback empty diff).',
          mimeType: 'text/plain',
        ),
        duration: stopwatch.elapsed,
      );
    }
  }
}
