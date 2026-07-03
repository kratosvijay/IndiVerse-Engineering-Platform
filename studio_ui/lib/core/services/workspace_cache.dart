import '../../models/tree_node.dart';

class WorkspaceCache {
  final Map<String, List<TreeNode>> _cache = {};
  int _hits = 0;
  int _misses = 0;

  List<TreeNode>? get(String path) {
    if (_cache.containsKey(path)) {
      _hits++;
      return _cache[path];
    }
    _misses++;
    return null;
  }

  void put(String path, List<TreeNode> children) {
    _cache[path] = children;
  }

  void invalidate(String path) {
    _cache.remove(path);
    // Also invalidate parent directory if necessary
    final parts = path.split('/');
    if (parts.length > 1) {
      parts.removeLast();
      final parent = parts.join('/');
      _cache.remove(parent);
    }
  }

  void clear() {
    _cache.clear();
  }

  Map<String, int> statistics() {
    return {"hits": _hits, "misses": _misses, "size": _cache.length};
  }
}
