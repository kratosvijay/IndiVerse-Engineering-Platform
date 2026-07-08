import '../../../models/tool_call_models.dart';
import '../tool_handler.dart';
import '../code_intelligence_service.dart';

class DiagnosticsListTool implements ToolHandler {
  @override
  final ToolDescriptor descriptor = const ToolDescriptor(
    id: 'diagnostics.list',
    name: 'List Diagnostics',
    description:
        'Get active warnings and errors (diagnostics) for files in the workspace.',
    category: ToolCategory.diagnostics,
    requiresPermission: false,
    readOnly: true,
    destructive: false,
    modifiesWorkspace: false,
    tags: ['diagnostics', 'errors', 'warnings'],
  );

  @override
  Future<ToolCallResult> execute(
      ToolCallRequest request, ToolExecutionContext context) async {
    final stopwatch = Stopwatch()..start();
    final path = request.arguments['path'] as String? ??
        request.arguments['filePath'] as String? ??
        '';

    try {
      final service = CodeIntelligenceService(context.sdk);
      final List<Map<String, dynamic>> results;

      if (path.isNotEmpty) {
        final diags = service.workspaceDiagnostics.getForFile(path);
        results = diags.map((d) => d.toJson()).toList();
      } else {
        final diags = service.workspaceDiagnostics.getAll();
        results = diags.map((d) => d.toJson()).toList();
      }

      return ToolCallResult(
        success: true,
        output: ToolOutput(
          data: results,
          displayText: 'Found ${results.length} diagnostics.',
          mimeType: 'application/json',
        ),
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      return ToolCallResult(
        success: false,
        output: ToolOutput(
          displayText: 'Failed to retrieve diagnostics: $e',
          mimeType: 'text/plain',
        ),
        duration: stopwatch.elapsed,
        errorCode: 'DIAGNOSTICS_FAILED',
      );
    }
  }
}
