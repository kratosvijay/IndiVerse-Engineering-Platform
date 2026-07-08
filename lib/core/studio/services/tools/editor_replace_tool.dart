import 'dart:io';
import '../../../models/tool_call_models.dart';
import '../tool_handler.dart';

class EditorReplaceTool implements ToolHandler {
  @override
  final ToolDescriptor descriptor = const ToolDescriptor(
    id: 'editor.replace',
    name: 'Replace Text in Editor',
    description: 'Replace a specific range of text in a workspace file.',
    category: ToolCategory.editor,
    requiresPermission: true,
    readOnly: false,
    destructive: false,
    modifiesWorkspace: true,
    tags: ['editor', 'replace', 'edit'],
  );

  @override
  Future<ToolCallResult> execute(ToolCallRequest request, ToolExecutionContext context) async {
    final stopwatch = Stopwatch()..start();
    final path = request.arguments['path'] as String? ?? request.arguments['filePath'] as String? ?? '';
    final startLine = request.arguments['startLine'] as int? ?? 1;
    final startColumn = request.arguments['startColumn'] as int? ?? 1;
    final endLine = request.arguments['endLine'] as int? ?? startLine;
    final endColumn = request.arguments['endColumn'] as int? ?? startColumn;
    final newText = request.arguments['newText'] as String? ?? '';

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
      final file = File('${Directory.current.path}/$path');
      if (!file.existsSync()) {
        return ToolCallResult(
          success: false,
          output: ToolOutput(
            displayText: 'File not found: $path',
            mimeType: 'text/plain',
          ),
          duration: stopwatch.elapsed,
          errorCode: 'FILE_NOT_FOUND',
        );
      }

      final content = file.readAsStringSync();
      
      int positionToOffset(String text, int line, int column) {
        final lines = text.split('\n');
        int offset = 0;
        for (int i = 0; i < line - 1; i++) {
          if (i < lines.length) {
            offset += lines[i].length + 1; // +1 for '\n'
          }
        }
        offset += column - 1;
        return offset.clamp(0, text.length);
      }

      final startOffset = positionToOffset(content, startLine, startColumn);
      final endOffset = positionToOffset(content, endLine, endColumn);

      if (startOffset > endOffset) {
        return ToolCallResult(
          success: false,
          output: const ToolOutput(
            displayText: 'Invalid text range: startOffset is greater than endOffset.',
            mimeType: 'text/plain',
          ),
          duration: stopwatch.elapsed,
          errorCode: 'INVALID_RANGE',
        );
      }

      final prefix = content.substring(0, startOffset);
      final suffix = content.substring(endOffset);
      final updatedContent = prefix + newText + suffix;

      file.writeAsStringSync(updatedContent);

      return ToolCallResult(
        success: true,
        output: ToolOutput(
          displayText: 'Successfully replaced text in "$path" at lines $startLine-$endLine.',
          mimeType: 'text/plain',
        ),
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      return ToolCallResult(
        success: false,
        output: ToolOutput(
          displayText: 'Failed to replace text in editor: $e',
          mimeType: 'text/plain',
        ),
        duration: stopwatch.elapsed,
        errorCode: 'REPLACE_FAILED',
      );
    }
  }
}
