import '../../models/language_intelligence_models.dart';

class CompletionCacheKey {
  final String language;
  final String providerVersion;
  final String path;
  final int revision;
  final String prefix;

  const CompletionCacheKey({
    required this.language,
    required this.providerVersion,
    required this.path,
    required this.revision,
    required this.prefix,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompletionCacheKey &&
          runtimeType == other.runtimeType &&
          language == other.language &&
          providerVersion == other.providerVersion &&
          path == other.path &&
          revision == other.revision &&
          prefix == other.prefix;

  @override
  int get hashCode =>
      language.hashCode ^
      providerVersion.hashCode ^
      path.hashCode ^
      revision.hashCode ^
      prefix.hashCode;
}

class CompletionCacheEntry {
  final List<CompletionItem> items;
  final DateTime timestamp;

  CompletionCacheEntry({required this.items, required this.timestamp});

  bool isExpired(Duration timeout) {
    return DateTime.now().difference(timestamp) > timeout;
  }
}

class CompletionCache {
  final Map<CompletionCacheKey, CompletionCacheEntry> _cache = {};
  final Duration timeout;

  CompletionCache({this.timeout = const Duration(seconds: 5)});

  void put(
    String language,
    String providerVersion,
    String path,
    int revision,
    String prefix,
    List<CompletionItem> items,
  ) {
    final key = CompletionCacheKey(
      language: language,
      providerVersion: providerVersion,
      path: path,
      revision: revision,
      prefix: prefix,
    );
    _cache[key] = CompletionCacheEntry(items: items, timestamp: DateTime.now());
  }

  List<CompletionItem>? get(
    String language,
    String providerVersion,
    String path,
    int revision,
    String prefix,
  ) {
    final key = CompletionCacheKey(
      language: language,
      providerVersion: providerVersion,
      path: path,
      revision: revision,
      prefix: prefix,
    );
    final entry = _cache[key];
    if (entry == null) return null;
    if (entry.isExpired(timeout)) {
      _cache.remove(key);
      return null;
    }
    return entry.items;
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
