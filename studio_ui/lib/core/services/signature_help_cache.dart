import '../../models/language_intelligence_models.dart';

class SignatureHelpCacheKey {
  final String workspace;
  final String path;
  final int revision;
  final String symbol;

  const SignatureHelpCacheKey({
    required this.workspace,
    required this.path,
    required this.revision,
    required this.symbol,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SignatureHelpCacheKey &&
          runtimeType == other.runtimeType &&
          workspace == other.workspace &&
          path == other.path &&
          revision == other.revision &&
          symbol == other.symbol;

  @override
  int get hashCode =>
      workspace.hashCode ^ path.hashCode ^ revision.hashCode ^ symbol.hashCode;
}

class SignatureHelpCacheEntry {
  final SignatureHelp help;
  final DateTime timestamp;

  SignatureHelpCacheEntry({required this.help, required this.timestamp});
}

class SignatureHelpCache {
  final Map<SignatureHelpCacheKey, SignatureHelpCacheEntry> _cache = {};

  void put(
    String workspace,
    String path,
    int revision,
    String symbol,
    SignatureHelp help,
  ) {
    final key = SignatureHelpCacheKey(
      workspace: workspace,
      path: path,
      revision: revision,
      symbol: symbol,
    );
    _cache[key] = SignatureHelpCacheEntry(
      help: help,
      timestamp: DateTime.now(),
    );
  }

  SignatureHelp? get(
    String workspace,
    String path,
    int revision,
    String symbol,
  ) {
    final key = SignatureHelpCacheKey(
      workspace: workspace,
      path: path,
      revision: revision,
      symbol: symbol,
    );
    final entry = _cache[key];
    if (entry == null) return null;
    return entry.help;
  }

  void invalidatePath(String path) {
    _cache.removeWhere((key, val) => key.path == path);
  }

  void invalidateRevision(String path, int revision) {
    _cache.removeWhere(
      (key, val) => key.path == path && key.revision != revision,
    );
  }

  void clear() {
    _cache.clear();
  }
}
