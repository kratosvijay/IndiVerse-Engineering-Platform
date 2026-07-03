import '../document.dart';

class DocumentCache {
  final Map<String, Document> _cache = {};

  void save(String uri, Document doc) {
    _cache[uri] = doc;
  }

  Document? get(String uri) => _cache[uri];

  void clear() => _cache.clear();
}
