import 'dart:async';

enum ContextPriority {
  selection,
  workspace,
  diagnostics,
  editor,
  git,
  history,
}

class ContextRequest {
  final String workspace;
  final String? activeFilePath;
  final String? selectedCode;
  final int maxTokens;

  const ContextRequest({
    required this.workspace,
    this.activeFilePath,
    this.selectedCode,
    required this.maxTokens,
  });
}

class ContextFragment {
  final String source;
  final String content;
  final int estimatedTokens;
  final ContextPriority priority;
  final String providerId;
  final String? sourcePath;
  final String? version;
  final bool cacheable;

  const ContextFragment({
    required this.source,
    required this.content,
    required this.estimatedTokens,
    required this.priority,
    required this.providerId,
    this.sourcePath,
    this.version,
    this.cacheable = false,
  });

  Map<String, dynamic> toJson() => {
        'source': source,
        'content': content,
        'estimatedTokens': estimatedTokens,
        'priority': priority.name,
        'providerId': providerId,
        'sourcePath': sourcePath,
        'version': version,
        'cacheable': cacheable,
      };
}

class ContextSnapshot {
  final List<ContextFragment> fragments;
  final DateTime timestamp;

  const ContextSnapshot({
    required this.fragments,
    required this.timestamp,
  });

  int get totalTokens => fragments.fold(0, (sum, f) => sum + f.estimatedTokens);

  Map<String, dynamic> toJson() => {
        'fragments': fragments.map((f) => f.toJson()).toList(),
        'timestamp': timestamp.toIso8601String(),
        'totalTokens': totalTokens,
      };
}

abstract class ContextProvider {
  String get id;
  Future<ContextFragment> resolve(ContextRequest request);
}

class SelectionContextProvider implements ContextProvider {
  @override
  final String id = 'selection';

  @override
  Future<ContextFragment> resolve(ContextRequest request) async {
    final code = request.selectedCode ?? '';
    final content = code.isNotEmpty ? 'Selected code:\n$code' : '';
    return ContextFragment(
      source: id,
      content: content,
      estimatedTokens: (content.length / 4.0).ceil(),
      priority: ContextPriority.selection,
      providerId: 'context.selection',
      sourcePath: request.activeFilePath,
      version: '1.0.0',
      cacheable: false,
    );
  }
}

class WorkspaceContextProvider implements ContextProvider {
  @override
  final String id = 'workspace';

  @override
  Future<ContextFragment> resolve(ContextRequest request) async {
    final text =
        'Active workspace: ${request.workspace}\nContains: lib/, test/';
    return ContextFragment(
      source: id,
      content: text,
      estimatedTokens: (text.length / 4.0).ceil(),
      priority: ContextPriority.workspace,
      providerId: 'context.workspace',
      version: '1.0.0',
      cacheable: true,
    );
  }
}

class GitContextProvider implements ContextProvider {
  @override
  final String id = 'git';

  @override
  Future<ContextFragment> resolve(ContextRequest request) async {
    final text =
        'Git branch: main\nChanges: 1 file modified (diagnostic_models.dart)';
    return ContextFragment(
      source: id,
      content: text,
      estimatedTokens: (text.length / 4.0).ceil(),
      priority: ContextPriority.git,
      providerId: 'context.git',
      version: '1.0.0',
      cacheable: false,
    );
  }
}

class DiagnosticsContextProvider implements ContextProvider {
  @override
  final String id = 'diagnostics';

  @override
  Future<ContextFragment> resolve(ContextRequest request) async {
    final text = 'Current diagnostic issues: 0 errors, 0 warnings';
    return ContextFragment(
      source: id,
      content: text,
      estimatedTokens: (text.length / 4.0).ceil(),
      priority: ContextPriority.diagnostics,
      providerId: 'context.diagnostics',
      version: '1.0.0',
      cacheable: false,
    );
  }
}

class EditorContextProvider implements ContextProvider {
  @override
  final String id = 'editor';

  @override
  Future<ContextFragment> resolve(ContextRequest request) async {
    final filePath = request.activeFilePath ?? 'None';
    final text = 'Active File: $filePath\nCursor position: Line 1, Col 1';
    return ContextFragment(
      source: id,
      content: text,
      estimatedTokens: (text.length / 4.0).ceil(),
      priority: ContextPriority.editor,
      providerId: 'context.editor',
      sourcePath: filePath,
      version: '1.0.0',
      cacheable: false,
    );
  }
}

class ContextEngine {
  final Map<String, ContextProvider> _providers = {};

  ContextEngine() {
    registerProvider(SelectionContextProvider());
    registerProvider(WorkspaceContextProvider());
    registerProvider(GitContextProvider());
    registerProvider(DiagnosticsContextProvider());
    registerProvider(EditorContextProvider());
  }

  void registerProvider(ContextProvider provider) {
    _providers[provider.id] = provider;
  }

  void unregisterProvider(String id) {
    _providers.remove(id);
  }

  Future<ContextSnapshot> gatherContext(ContextRequest request) async {
    final fragments = <ContextFragment>[];
    for (final provider in _providers.values) {
      try {
        final fragment = await provider.resolve(request);
        fragments.add(fragment);
      } catch (_) {}
    }
    return ContextSnapshot(
      fragments: fragments,
      timestamp: DateTime.now(),
    );
  }
}
