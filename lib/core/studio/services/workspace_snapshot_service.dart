import 'dart:convert';
import 'dart:io';

class WorkspaceSnapshot {
  final String id;
  final String path;
  final DateTime createdAt;
  final String checksum;

  const WorkspaceSnapshot({
    required this.id,
    required this.path,
    required this.createdAt,
    required this.checksum,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'path': path,
        'createdAt': createdAt.toIso8601String(),
        'checksum': checksum,
      };

  factory WorkspaceSnapshot.fromJson(Map<String, dynamic> json) => WorkspaceSnapshot(
        id: json['id'] as String,
        path: json['path'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        checksum: json['checksum'] as String,
      );
}

class WorkspaceSnapshotService {
  final String baseDir;
  final Set<String> _capturedKeys = {};
  final Map<String, WorkspaceSnapshot> _snapshots = {};

  WorkspaceSnapshotService({this.baseDir = '.indiverse'});

  Future<WorkspaceSnapshot?> captureSnapshot(String filePath, String requestId) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return null;
    }

    // Deduplicate: check if this file was already snapshotted for this request ID
    final dedupeKey = '$requestId:$filePath';
    if (_capturedKeys.contains(dedupeKey)) {
      for (final s in _snapshots.values) {
        if (s.path == filePath) {
          return s;
        }
      }
      return null;
    }

    try {
      final bytes = await file.readAsBytes();
      final checksum = _computeChecksum(bytes);
      final snapshotId = 'snap-${DateTime.now().microsecondsSinceEpoch}';

      // Create backup directory
      final backupDir = Directory('$baseDir/snapshots');
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      // Write backup file
      final backupFile = File('${backupDir.path}/$snapshotId.bak');
      await backupFile.writeAsBytes(bytes);

      final snapshot = WorkspaceSnapshot(
        id: snapshotId,
        path: filePath,
        createdAt: DateTime.now(),
        checksum: checksum,
      );

      _capturedKeys.add(dedupeKey);
      _snapshots[snapshotId] = snapshot;

      return snapshot;
    } catch (_) {
      return null;
    }
  }

  Future<bool> restoreSnapshot(String snapshotId) async {
    final snapshot = _snapshots[snapshotId];
    if (snapshot == null) {
      return false;
    }

    final backupFile = File('$baseDir/snapshots/$snapshotId.bak');
    if (!await backupFile.exists()) {
      return false;
    }

    try {
      final targetFile = File(snapshot.path);
      // Ensure parent directory exists
      final parentDir = targetFile.parent;
      if (!await parentDir.exists()) {
        await parentDir.create(recursive: true);
      }

      final bytes = await backupFile.readAsBytes();
      await targetFile.writeAsBytes(bytes);
      return true;
    } catch (_) {
      return false;
    }
  }

  String _computeChecksum(List<int> bytes) {
    var hash = 2166136261;
    for (final b in bytes) {
      hash ^= b;
      hash = (hash * 16777619) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  void clearDeduplicationCache() {
    _capturedKeys.clear();
  }

  WorkspaceSnapshot? getSnapshot(String snapshotId) => _snapshots[snapshotId];
}
