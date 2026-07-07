import 'dart:async';

class ContextRequest {
  final String workspace;
  final String? activeFilePath;
  final int maxTokens;

  const ContextRequest({
    required this.workspace,
    this.activeFilePath,
    required this.maxTokens,
  });
}

class ContextFragment {
  final String source;
  final String content;
  final int estimatedTokens;
  final int priority;

  const ContextFragment({
    required this.source,
    required this.content,
    required this.estimatedTokens,
    required this.priority,
  });

  Map<String, dynamic> toJson() => {
        'source': source,
        'content': content,
        'estimatedTokens': estimatedTokens,
        'priority': priority,
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
      priority: 1,
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
      priority: 2,
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
      priority: 3,
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
      priority: 4,
    );
  }
}

class ContextEngine {
  final Map<String, ContextProvider> _providers = {};

  ContextEngine() {
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
