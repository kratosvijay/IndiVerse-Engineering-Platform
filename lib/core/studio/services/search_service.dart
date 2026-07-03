import 'dart:io';
import '../../../../platform_sdk/platform_sdk.dart';

class SearchService {
  final PlatformSDK sdk;

  SearchService(this.sdk);

  Future<List<Map<String, dynamic>>> searchCodebase({
    required String query,
    required String mode,
    int page = 1,
    int pageSize = 20,
  }) async {
    if (query.isEmpty) return const [];

    final root = Directory.current;
    final results = <Map<String, dynamic>>[];

    final list = root.listSync(recursive: true);
    for (final entity in list) {
      if (entity is File) {
        final relPath = entity.path.replaceFirst(root.path, "");
        if (relPath.contains('/.') ||
            relPath.contains('node_modules') ||
            relPath.contains('build/')) {
          continue;
        }

        try {
          final content = entity.readAsStringSync();
          final lines = content.split('\n');

          for (var i = 0; i < lines.length; i++) {
            final line = lines[i];
            if (line.contains(query)) {
              results.add({
                "filePath": relPath,
                "lineNumber": i + 1,
                "snippet": line.trim(),
                "score": mode == "semantic" ? 0.88 : 0.98,
                "mode": mode,
                "explanation":
                    "Match found for '$query' using $mode search mode",
                "symbols": [query],
              });
            }
          }
        } catch (_) {
          // Skip binary files or encoding errors
        }
      }
    }

    // Basic pagination
    final startIndex = (page - 1) * pageSize;
    if (startIndex >= results.length) return const [];
    final endIndex = (startIndex + pageSize) < results.length
        ? (startIndex + pageSize)
        : results.length;

    return results.sublist(startIndex, endIndex);
  }
}
