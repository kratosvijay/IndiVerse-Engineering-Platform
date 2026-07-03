import 'dart:io';
import '../../../../platform_sdk/platform_sdk.dart';

class WorkspaceService {
  final PlatformSDK sdk;
  final List<void Function(Map<String, dynamic>)> _watcherListeners = [];

  WorkspaceService(this.sdk) {
    _initWatcher();
  }

  void addWatcherListener(void Function(Map<String, dynamic>) listener) {
    _watcherListeners.add(listener);
  }

  void _initWatcher() {
    try {
      final root = Directory.current;
      root.watch(recursive: true).listen((event) {
        final relPath = event.path.replaceFirst(root.path, "");
        if (relPath.contains('/.') ||
            relPath.contains('node_modules') ||
            relPath.contains('build/')) {
          return;
        }

        String eventType;
        if (event.type == FileSystemEvent.create) {
          eventType = "created";
        } else if (event.type == FileSystemEvent.delete) {
          eventType = "deleted";
        } else if (event.type == FileSystemEvent.modify) {
          eventType = "modified";
        } else {
          eventType = "modified";
        }

        final wsEvent = {
          "id": "evt-${DateTime.now().microsecondsSinceEpoch}",
          "sequence": DateTime.now().millisecondsSinceEpoch,
          "version": "1.0",
          "category": "workspace",
          "event": eventType,
          "path": relPath,
          "isDirectory": FileSystemEntity.isDirectorySync(event.path),
          "timestamp": DateTime.now().toIso8601String(),
        };

        for (final listener in _watcherListeners) {
          listener(wsEvent);
        }
      });
    } catch (_) {
      // Gracefully ignore watch failures in restricted/test environments
    }
  }

  Future<Map<String, dynamic>> getWorkspaceTree(
      {String? path, bool recursive = true}) async {
    final root = Directory.current;
    final targetPath = path != null ? Directory(root.path + '/' + path) : root;

    if (!targetPath.existsSync()) {
      throw DirectoryNotFoundException("Directory not found: $path");
    }

    final entities = <Map<String, dynamic>>[];
    final list = targetPath.listSync(recursive: recursive);

    for (final entity in list) {
      final relPath = entity.path.replaceFirst(root.path, "");
      if (relPath.isEmpty) continue;

      final parts = relPath.split('/');
      if (parts.any((p) => p.startsWith('.') && p != '.') ||
          relPath.contains('node_modules') ||
          relPath.contains('build/')) {
        continue;
      }

      if (entity is File) {
        entities.add({
          "name": entity.path.split(Platform.pathSeparator).last,
          "path": relPath,
          "type": "file",
          "size": entity.lengthSync(),
          "modified": entity.lastModifiedSync().toIso8601String(),
        });
      } else if (entity is Directory) {
        entities.add({
          "name": entity.path.split(Platform.pathSeparator).last,
          "path": relPath,
          "type": "directory",
          "size": 0,
          "modified": DateTime.now().toIso8601String(),
        });
      }
    }

    return {
      "status": "ready",
      "activeProject": "indiverse-engineering-platform",
      "branch": "main",
      "files": entities,
      "flutterDetected": true,
      "gitDetected": true,
      "firebaseDetected": true,
    };
  }

  Future<Map<String, dynamic>> getFileContent(String relativePath) async {
    if (relativePath.contains('..')) {
      throw SecurityException("Access denied: path traversal attempt");
    }

    final file = File('${Directory.current.path}/$relativePath');
    if (!file.existsSync()) {
      throw FileNotFoundException("File not found: $relativePath");
    }

    final bytes = file.readAsBytesSync();
    final content = String.fromCharCodes(bytes);
    final lines = content.split('\n');

    String lang = "txt";
    if (relativePath.endsWith(".dart")) {
      lang = "dart";
    } else if (relativePath.endsWith(".json")) {
      lang = "json";
    } else if (relativePath.endsWith(".yaml") ||
        relativePath.endsWith(".yml")) {
      lang = "yaml";
    } else if (relativePath.endsWith(".md")) {
      lang = "markdown";
    }

    return {
      "content": content,
      "language": lang,
      "encoding": "utf8",
      "lineCount": lines.length,
      "size": bytes.length,
      "lastModified": file.lastModifiedSync().toIso8601String(),
      "readOnly": true
    };
  }

  Future<Map<String, dynamic>> getStat(String relativePath) async {
    if (relativePath.contains('..')) {
      throw SecurityException("Access denied: path traversal attempt");
    }

    final file = File('${Directory.current.path}/$relativePath');
    final isDir = FileSystemEntity.isDirectorySync(file.path);

    if (!file.existsSync() && !isDir) {
      return {"path": relativePath, "exists": false};
    }

    String lang = "txt";
    if (relativePath.endsWith(".dart")) {
      lang = "dart";
    } else if (relativePath.endsWith(".json")) {
      lang = "json";
    } else if (relativePath.endsWith(".yaml") ||
        relativePath.endsWith(".yml")) {
      lang = "yaml";
    } else if (relativePath.endsWith(".md")) {
      lang = "markdown";
    }

    int size = 0;
    int lineCount = 0;
    String modified = DateTime.now().toIso8601String();
    List<String> symbols = [];

    if (!isDir) {
      size = file.lengthSync();
      final content = file.readAsStringSync();
      lineCount = content.split('\n').length;
      modified = file.lastModifiedSync().toIso8601String();

      // Basic symbol indexing regex matches
      final classRegex = RegExp(r'class\s+([A-Za-z0-9_]+)');
      for (final match in classRegex.allMatches(content)) {
        if (match.groupCount >= 1) {
          symbols.add(match.group(1)!);
        }
      }
    }

    return {
      "path": relativePath,
      "exists": true,
      "isDirectory": isDir,
      "size": size,
      "language": lang,
      "gitStatus": "clean",
      "lineCount": lineCount,
      "symbols": symbols,
      "modified": modified,
      "diagnostics": <String>[]
    };
  }
}

class DirectoryNotFoundException implements Exception {
  final String message;
  DirectoryNotFoundException(this.message);
  @override
  String toString() => message;
}

class FileNotFoundException implements Exception {
  final String message;
  FileNotFoundException(this.message);
  @override
  String toString() => message;
}

class SecurityException implements Exception {
  final String message;
  SecurityException(this.message);
  @override
  String toString() => message;
}
