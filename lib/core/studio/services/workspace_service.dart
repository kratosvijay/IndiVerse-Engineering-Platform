import 'dart:io';
import '../../../../platform_sdk/platform_sdk.dart';

class WorkspaceService {
  final PlatformSDK sdk;

  WorkspaceService(this.sdk);

  Future<Map<String, dynamic>> getWorkspaceTree(
      {String? path, bool recursive = true}) async {
    final root = Directory.current;
    final targetPath = path != null ? Directory(root.path + '/' + path) : root;

    if (!targetPath.existsSync()) {
      throw DirectoryNotFoundException("Directory not found: $path");
    }

    final files = <Map<String, dynamic>>[];
    final list = targetPath.listSync(recursive: recursive);

    for (final entity in list) {
      if (entity is File) {
        final relPath = entity.path.replaceFirst(root.path, "");
        if (relPath.contains('/.') ||
            relPath.contains('node_modules') ||
            relPath.contains('build/')) {
          continue;
        }
        files.add({
          "name": entity.path.split(Platform.pathSeparator).last,
          "path": relPath,
          "size": entity.lengthSync(),
          "modified": entity.lastModifiedSync().toIso8601String(),
        });
      }
    }

    return {
      "status": "ready",
      "activeProject": "indiverse-engineering-platform",
      "branch": "main",
      "files": files,
      "flutterDetected": true,
      "gitDetected": true,
      "firebaseDetected": true,
    };
  }
}

class DirectoryNotFoundException implements Exception {
  final String message;
  DirectoryNotFoundException(this.message);
  @override
  String toString() => message;
}
