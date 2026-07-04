import '../../models/semantic_token.dart';
import 'semantic_token_decoder.dart';

class SemanticTokenIndex {
  final Map<int, List<SemanticToken>> tokensByLine;

  const SemanticTokenIndex({required this.tokensByLine});

  factory SemanticTokenIndex.build(List<SemanticToken> tokens) {
    final Map<int, List<SemanticToken>> map = {};
    for (final token in tokens) {
      map.putIfAbsent(token.start.line, () => []).add(token);
    }
    return SemanticTokenIndex(tokensByLine: map);
  }
}

class SemanticCacheEntry {
  final SemanticTokenIndex index;
  final int localRevision;
  final int providerVersion;
  final SemanticCacheState state;
  final DateTime timestamp;

  const SemanticCacheEntry({
    required this.index,
    required this.localRevision,
    required this.providerVersion,
    required this.state,
    required this.timestamp,
  });
}

class SemanticTokenCache {
  final Map<String, SemanticCacheEntry> _cache = {};

  SemanticCacheEntry? get(String documentPath) => _cache[documentPath];

  void put(String documentPath, SemanticCacheEntry entry) {
    _cache[documentPath] = entry;
  }

  void remove(String documentPath) {
    _cache.remove(documentPath);
  }

  void clear() {
    _cache.clear();
  }

  void merge(
    String documentPath,
    List<SemanticToken> newTokens,
    int fromLine,
    int toLine,
    int localRevision,
    int providerVersion,
  ) {
    final existingEntry = _cache[documentPath];
    if (existingEntry == null || existingEntry.localRevision != localRevision) {
      final sortedTokens = SemanticTokenNormalizer.normalize(newTokens);
      put(
        documentPath,
        SemanticCacheEntry(
          index: SemanticTokenIndex.build(sortedTokens),
          localRevision: localRevision,
          providerVersion: providerVersion,
          state: SemanticCacheState.ready,
          timestamp: DateTime.now(),
        ),
      );
      return;
    }

    final List<SemanticToken> merged = [];

    existingEntry.index.tokensByLine.forEach((line, lineTokens) {
      if (line < fromLine || line > toLine) {
        merged.addAll(lineTokens);
      }
    });

    merged.addAll(newTokens);

    final normalized = SemanticTokenNormalizer.normalize(merged);
    put(
      documentPath,
      SemanticCacheEntry(
        index: SemanticTokenIndex.build(normalized),
        localRevision: localRevision,
        providerVersion: providerVersion,
        state: SemanticCacheState.ready,
        timestamp: DateTime.now(),
      ),
    );
  }
}
