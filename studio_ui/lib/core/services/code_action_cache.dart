import '../../models/language_intelligence_models.dart';
import '../../models/editor_document.dart';

class CodeActionCacheKey {
  final String workspace;
  final String path;
  final int revision;
  final String selectionKey;
  final String diagnosticIdsKey;

  CodeActionCacheKey({
    required this.workspace,
    required this.path,
    required this.revision,
    required this.selectionKey,
    required this.diagnosticIdsKey,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CodeActionCacheKey &&
          runtimeType == other.runtimeType &&
          workspace == other.workspace &&
          path == other.path &&
          revision == other.revision &&
          selectionKey == other.selectionKey &&
          diagnosticIdsKey == other.diagnosticIdsKey;

  @override
  int get hashCode =>
      workspace.hashCode ^
      path.hashCode ^
      revision.hashCode ^
      selectionKey.hashCode ^
      diagnosticIdsKey.hashCode;
}

class CodeActionCache {
  final Map<CodeActionCacheKey, List<CodeAction>> _cache = {};

  List<CodeAction>? get(
    String workspace,
    String path,
    int revision,
    Position pos,
    List<String> diagnosticIds,
  ) {
    final key = CodeActionCacheKey(
      workspace: workspace,
      path: path,
      revision: revision,
      selectionKey: '${pos.line}:${pos.column}',
      diagnosticIdsKey: (List<String>.from(diagnosticIds)..sort()).join(','),
    );
    return _cache[key];
  }

  void put(
    String workspace,
    String path,
    int revision,
    Position pos,
    List<String> diagnosticIds,
    List<CodeAction> actions,
  ) {
    final key = CodeActionCacheKey(
      workspace: workspace,
      path: path,
      revision: revision,
      selectionKey: '${pos.line}:${pos.column}',
      diagnosticIdsKey: (List<String>.from(diagnosticIds)..sort()).join(','),
    );
    _cache[key] = actions;
  }

  void invalidatePath(String path) {
    _cache.removeWhere((key, val) => key.path == path);
  }

  void clear() {
    _cache.clear();
  }
}
