import 'workspace.dart';

class WorkspaceCache {
  final Map<String, Workspace> _cache = {};
  final Map<String, String> _fileHashes = {};

  Future<void> save(String rootPath, Workspace workspace) async {
    _cache[rootPath] = workspace;
  }

  Future<Workspace?> load(String rootPath) async {
    return _cache[rootPath];
  }

  void updateFileHash(String filepath, String hash) {
    _fileHashes[filepath] = hash;
  }

  String? getFileHash(String filepath) => _fileHashes[filepath];
}
