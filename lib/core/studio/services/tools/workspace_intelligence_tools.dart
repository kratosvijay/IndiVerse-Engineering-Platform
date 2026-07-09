import '../../../models/tool_call_models.dart';
import '../tool_handler.dart';
import '../../../workspace/workspace_intelligence.dart';

class FindSymbolTool implements ToolHandler {
  @override
  final ToolDescriptor descriptor = const ToolDescriptor(
    id: 'workspace.find_symbol',
    name: 'Find Symbol',
    description: 'Find symbols matching query in the workspace.',
    category: ToolCategory.workspace,
    requiresPermission: false,
    readOnly: true,
    destructive: false,
    modifiesWorkspace: false,
    tags: ['symbol', 'search', 'intelligence'],
  );

  @override
  Future<ToolCallResult> execute(
      ToolCallRequest request, ToolExecutionContext context) async {
    final stopwatch = Stopwatch()..start();
    final query = request.arguments['query'] as String? ?? '';

    final intel = WorkspaceIntelligenceRegistry.active ??
        WorkspaceIntelligenceRegistry.get(context.workspaceId);

    if (intel == null) {
      return ToolCallResult(
        success: false,
        output: const ToolOutput(
            displayText: 'Workspace intelligence not initialized.',
            mimeType: 'text/plain'),
        duration: stopwatch.elapsed,
        errorCode: 'INTEL_NOT_INITIALIZED',
      );
    }

    final res = intel.findSymbol(query);
    return ToolCallResult(
      success: true,
      output: ToolOutput(
        data: {
          'items': res.items.map((s) => s.id).toList(),
          'totalCount': res.totalCount,
          'elapsedMs': res.elapsed.inMilliseconds,
          'truncated': res.truncated,
        },
        displayText: 'Found ${res.totalCount} symbols matching "$query".',
        mimeType: 'application/json',
      ),
      duration: stopwatch.elapsed,
    );
  }
}

class FindReferencesTool implements ToolHandler {
  @override
  final ToolDescriptor descriptor = const ToolDescriptor(
    id: 'workspace.find_references',
    name: 'Find References',
    description: 'Find all references to a symbol in the workspace.',
    category: ToolCategory.workspace,
    requiresPermission: false,
    readOnly: true,
    destructive: false,
    modifiesWorkspace: false,
    tags: ['symbol', 'references', 'intelligence'],
  );

  @override
  Future<ToolCallResult> execute(
      ToolCallRequest request, ToolExecutionContext context) async {
    final stopwatch = Stopwatch()..start();
    final symbol = request.arguments['symbol'] as String? ??
        request.arguments['symbolName'] as String? ??
        '';

    final intel = WorkspaceIntelligenceRegistry.active ??
        WorkspaceIntelligenceRegistry.get(context.workspaceId);

    if (intel == null) {
      return ToolCallResult(
        success: false,
        output: const ToolOutput(
            displayText: 'Workspace intelligence not initialized.',
            mimeType: 'text/plain'),
        duration: stopwatch.elapsed,
        errorCode: 'INTEL_NOT_INITIALIZED',
      );
    }

    final res = intel.findReferences(symbol);
    return ToolCallResult(
      success: true,
      output: ToolOutput(
        data: {
          'items': res.items,
          'totalCount': res.totalCount,
          'elapsedMs': res.elapsed.inMilliseconds,
          'truncated': res.truncated,
        },
        displayText: 'Found ${res.totalCount} references to symbol "$symbol".',
        mimeType: 'application/json',
      ),
      duration: stopwatch.elapsed,
    );
  }
}

class FindImplementationsTool implements ToolHandler {
  @override
  final ToolDescriptor descriptor = const ToolDescriptor(
    id: 'workspace.find_implementations',
    name: 'Find Implementations',
    description: 'Find implementations or subclasses of a class.',
    category: ToolCategory.workspace,
    requiresPermission: false,
    readOnly: true,
    destructive: false,
    modifiesWorkspace: false,
    tags: ['class', 'inheritance', 'intelligence'],
  );

  @override
  Future<ToolCallResult> execute(
      ToolCallRequest request, ToolExecutionContext context) async {
    final stopwatch = Stopwatch()..start();
    final className = request.arguments['className'] as String? ??
        request.arguments['class'] as String? ??
        '';

    final intel = WorkspaceIntelligenceRegistry.active ??
        WorkspaceIntelligenceRegistry.get(context.workspaceId);

    if (intel == null) {
      return ToolCallResult(
        success: false,
        output: const ToolOutput(
            displayText: 'Workspace intelligence not initialized.',
            mimeType: 'text/plain'),
        duration: stopwatch.elapsed,
        errorCode: 'INTEL_NOT_INITIALIZED',
      );
    }

    final res = intel.findImplementations(className);
    return ToolCallResult(
      success: true,
      output: ToolOutput(
        data: {
          'items': res.items.map((s) => s.id).toList(),
          'totalCount': res.totalCount,
          'elapsedMs': res.elapsed.inMilliseconds,
          'truncated': res.truncated,
        },
        displayText: 'Found ${res.totalCount} implementations of "$className".',
        mimeType: 'application/json',
      ),
      duration: stopwatch.elapsed,
    );
  }
}

class FindCallersTool implements ToolHandler {
  @override
  final ToolDescriptor descriptor = const ToolDescriptor(
    id: 'workspace.find_callers',
    name: 'Find Callers',
    description: 'Find all methods/functions calling the specified method.',
    category: ToolCategory.workspace,
    requiresPermission: false,
    readOnly: true,
    destructive: false,
    modifiesWorkspace: false,
    tags: ['calltree', 'callers', 'intelligence'],
  );

  @override
  Future<ToolCallResult> execute(
      ToolCallRequest request, ToolExecutionContext context) async {
    final stopwatch = Stopwatch()..start();
    final methodName = request.arguments['methodName'] as String? ??
        request.arguments['method'] as String? ??
        '';

    final intel = WorkspaceIntelligenceRegistry.active ??
        WorkspaceIntelligenceRegistry.get(context.workspaceId);

    if (intel == null) {
      return ToolCallResult(
        success: false,
        output: const ToolOutput(
            displayText: 'Workspace intelligence not initialized.',
            mimeType: 'text/plain'),
        duration: stopwatch.elapsed,
        errorCode: 'INTEL_NOT_INITIALIZED',
      );
    }

    final res = intel.findCallers(methodName);
    return ToolCallResult(
      success: true,
      output: ToolOutput(
        data: {
          'items': res.items,
          'totalCount': res.totalCount,
          'elapsedMs': res.elapsed.inMilliseconds,
          'truncated': res.truncated,
        },
        displayText: 'Found ${res.totalCount} callers for "$methodName".',
        mimeType: 'application/json',
      ),
      duration: stopwatch.elapsed,
    );
  }
}

class FindCalleesTool implements ToolHandler {
  @override
  final ToolDescriptor descriptor = const ToolDescriptor(
    id: 'workspace.find_callees',
    name: 'Find Callees',
    description: 'Find all methods/functions called by the specified method.',
    category: ToolCategory.workspace,
    requiresPermission: false,
    readOnly: true,
    destructive: false,
    modifiesWorkspace: false,
    tags: ['calltree', 'callees', 'intelligence'],
  );

  @override
  Future<ToolCallResult> execute(
      ToolCallRequest request, ToolExecutionContext context) async {
    final stopwatch = Stopwatch()..start();
    final methodName = request.arguments['methodName'] as String? ??
        request.arguments['method'] as String? ??
        '';

    final intel = WorkspaceIntelligenceRegistry.active ??
        WorkspaceIntelligenceRegistry.get(context.workspaceId);

    if (intel == null) {
      return ToolCallResult(
        success: false,
        output: const ToolOutput(
            displayText: 'Workspace intelligence not initialized.',
            mimeType: 'text/plain'),
        duration: stopwatch.elapsed,
        errorCode: 'INTEL_NOT_INITIALIZED',
      );
    }

    final res = intel.findCallees(methodName);
    return ToolCallResult(
      success: true,
      output: ToolOutput(
        data: {
          'items': res.items,
          'totalCount': res.totalCount,
          'elapsedMs': res.elapsed.inMilliseconds,
          'truncated': res.truncated,
        },
        displayText: 'Found ${res.totalCount} callees for "$methodName".',
        mimeType: 'application/json',
      ),
      duration: stopwatch.elapsed,
    );
  }
}

class FindDefinitionTool implements ToolHandler {
  @override
  final ToolDescriptor descriptor = const ToolDescriptor(
    id: 'workspace.find_definition',
    name: 'Find Definition',
    description: 'Find definition of a symbol in the workspace.',
    category: ToolCategory.workspace,
    requiresPermission: false,
    readOnly: true,
    destructive: false,
    modifiesWorkspace: false,
    tags: ['symbol', 'definition', 'intelligence'],
  );

  @override
  Future<ToolCallResult> execute(
      ToolCallRequest request, ToolExecutionContext context) async {
    final stopwatch = Stopwatch()..start();
    final symbol = request.arguments['symbol'] as String? ??
        request.arguments['symbolName'] as String? ??
        '';

    final intel = WorkspaceIntelligenceRegistry.active ??
        WorkspaceIntelligenceRegistry.get(context.workspaceId);

    if (intel == null) {
      return ToolCallResult(
        success: false,
        output: const ToolOutput(
            displayText: 'Workspace intelligence not initialized.',
            mimeType: 'text/plain'),
        duration: stopwatch.elapsed,
        errorCode: 'INTEL_NOT_INITIALIZED',
      );
    }

    final res = intel.findDefinition(symbol);
    return ToolCallResult(
      success: true,
      output: ToolOutput(
        data: {
          'items': res.items.map((s) => s.id).toList(),
          'totalCount': res.totalCount,
          'elapsedMs': res.elapsed.inMilliseconds,
          'truncated': res.truncated,
        },
        displayText: res.totalCount > 0
            ? 'Found definition for "$symbol" at ${res.items.first.filePath}:${res.items.first.startLine}.'
            : 'Definition not found for "$symbol".',
        mimeType: 'application/json',
      ),
      duration: stopwatch.elapsed,
    );
  }
}

class FindFileTool implements ToolHandler {
  @override
  final ToolDescriptor descriptor = const ToolDescriptor(
    id: 'workspace.find_file',
    name: 'Find File',
    description: 'Find files matching pattern in the workspace.',
    category: ToolCategory.workspace,
    requiresPermission: false,
    readOnly: true,
    destructive: false,
    modifiesWorkspace: false,
    tags: ['file', 'glob', 'search'],
  );

  @override
  Future<ToolCallResult> execute(
      ToolCallRequest request, ToolExecutionContext context) async {
    final stopwatch = Stopwatch()..start();
    final pattern = request.arguments['pattern'] as String? ?? '';

    final intel = WorkspaceIntelligenceRegistry.active ??
        WorkspaceIntelligenceRegistry.get(context.workspaceId);

    if (intel == null) {
      return ToolCallResult(
        success: false,
        output: const ToolOutput(
            displayText: 'Workspace intelligence not initialized.',
            mimeType: 'text/plain'),
        duration: stopwatch.elapsed,
        errorCode: 'INTEL_NOT_INITIALIZED',
      );
    }

    final res = intel.findFiles(pattern);
    return ToolCallResult(
      success: true,
      output: ToolOutput(
        data: {
          'items': res.items,
          'totalCount': res.totalCount,
          'elapsedMs': res.elapsed.inMilliseconds,
          'truncated': res.truncated,
        },
        displayText: 'Found ${res.totalCount} files matching "$pattern".',
        mimeType: 'application/json',
      ),
      duration: stopwatch.elapsed,
    );
  }
}
