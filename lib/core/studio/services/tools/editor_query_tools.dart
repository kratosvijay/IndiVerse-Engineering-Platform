import '../../../models/tool_call_models.dart';
import '../tool_handler.dart';

class EditorCurrentFileTool implements ToolHandler {
  @override
  final ToolDescriptor descriptor = const ToolDescriptor(
    id: 'editor.currentFile',
    name: 'Current File',
    description: 'Get the path of the currently active file in the editor.',
    category: ToolCategory.editor,
    requiresPermission: false,
    readOnly: true,
    destructive: false,
    modifiesWorkspace: false,
    tags: ['editor', 'active', 'file'],
  );

  @override
  Future<ToolCallResult> execute(
      ToolCallRequest request, ToolExecutionContext context) async {
    final stopwatch = Stopwatch()..start();
    final path = context.metadata['activeFilePath'] as String? ?? '';

    return ToolCallResult(
      success: true,
      output: ToolOutput(
        data: {'path': path},
        displayText: path.isEmpty
            ? 'No active file in the editor.'
            : 'Active file: "$path".',
        mimeType: 'application/json',
      ),
      duration: stopwatch.elapsed,
    );
  }
}

class EditorSelectionTool implements ToolHandler {
  @override
  final ToolDescriptor descriptor = const ToolDescriptor(
    id: 'editor.selection',
    name: 'Current Selection',
    description: 'Get the active text selection range and selected content.',
    category: ToolCategory.editor,
    requiresPermission: false,
    readOnly: true,
    destructive: false,
    modifiesWorkspace: false,
    tags: ['editor', 'selection', 'range'],
  );

  @override
  Future<ToolCallResult> execute(
      ToolCallRequest request, ToolExecutionContext context) async {
    final stopwatch = Stopwatch()..start();
    final selectedCode = context.metadata['selectedCode'] as String? ?? '';
    final selectionStartLine =
        context.metadata['selectionStartLine'] as int? ?? 0;
    final selectionStartCol =
        context.metadata['selectionStartColumn'] as int? ?? 0;
    final selectionEndLine = context.metadata['selectionEndLine'] as int? ?? 0;
    final selectionEndCol = context.metadata['selectionEndColumn'] as int? ?? 0;

    return ToolCallResult(
      success: true,
      output: ToolOutput(
        data: {
          'text': selectedCode,
          'startLine': selectionStartLine,
          'startColumn': selectionStartCol,
          'endLine': selectionEndLine,
          'endColumn': selectionEndCol,
        },
        displayText: selectedCode.isEmpty
            ? 'No active text selection.'
            : 'Selected text:\n$selectedCode',
        mimeType: 'application/json',
      ),
      duration: stopwatch.elapsed,
    );
  }
}
