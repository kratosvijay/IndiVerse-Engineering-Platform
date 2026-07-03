import 'dart:io';
import 'ignore_rules.dart';

class IndexStatistics {
  final int filesIndexed;
  final int directories;
  final int skippedFiles;
  final int ignoredFiles;
  final double averageFileSize;
  final Duration indexTime;

  const IndexStatistics({
    this.filesIndexed = 0,
    this.directories = 0,
    this.skippedFiles = 0,
    this.ignoredFiles = 0,
    this.averageFileSize = 0.0,
    this.indexTime = Duration.zero,
  });
}

class WorkspaceIndexer {
  final IgnoreRules ignoreRules;

  WorkspaceIndexer({IgnoreRules? ignoreRules})
      : ignoreRules = ignoreRules ?? IgnoreRules();

  Future<IndexStatistics> index(String rootPath) async {
    final watch = Stopwatch()..start();
    var fileCount = 0;
    var dirCount = 0;
    var ignoredCount = 0;

    final dir = Directory(rootPath);
    if (await dir.exists()) {
      await for (final entity
          in dir.list(recursive: true, followLinks: false)) {
        if (ignoreRules.shouldIgnore(entity.path)) {
          ignoredCount++;
          continue;
        }
        if (entity is File) {
          fileCount++;
        } else if (entity is Directory) {
          dirCount++;
        }
      }
    }
    watch.stop();

    return IndexStatistics(
      filesIndexed: fileCount,
      directories: dirCount,
      ignoredFiles: ignoredCount,
      indexTime: watch.elapsed,
    );
  }
}
