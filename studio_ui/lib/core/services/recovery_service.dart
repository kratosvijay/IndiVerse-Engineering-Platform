import 'dart:convert';
import 'dart:io';

import '../../models/editor_document.dart';

class RecoveredDocument {
  final String path;
  final Position cursor;
  final SelectionRange? selection;
  final double scrollOffset;
  final List<RecoveredFold> folds;
  final int revision;
  final bool isDirty;
  final String buffer;

  RecoveredDocument({
    required this.path,
    required this.cursor,
    this.selection,
    required this.scrollOffset,
    required this.folds,
    required this.revision,
    required this.isDirty,
    required this.buffer,
  });

  Map<String, dynamic> toJson() => {
    'path': path,
    'cursor': {'line': cursor.line, 'column': cursor.column},
    'selection': selection != null
        ? {
            'startLine': selection!.start.line,
            'startColumn': selection!.start.column,
            'endLine': selection!.end.line,
            'endColumn': selection!.end.column,
          }
        : null,
    'scroll': scrollOffset,
    'folds': folds.map((f) => f.toJson()).toList(),
    'revision': revision,
    'dirty': isDirty,
    'buffer': buffer,
  };

  factory RecoveredDocument.fromJson(Map<String, dynamic> json) {
    final cursorMap = json['cursor'] as Map<String, dynamic>;
    final selectionMap = json['selection'] as Map<String, dynamic>?;
    final foldsList = json['folds'] as List? ?? [];

    return RecoveredDocument(
      path: json['path'] as String? ?? '',
      cursor: Position(
        line: cursorMap['line'] as int? ?? 1,
        column: cursorMap['column'] as int? ?? 1,
      ),
      selection: selectionMap != null
          ? SelectionRange(
              start: Position(
                line: selectionMap['startLine'] as int? ?? 1,
                column: selectionMap['startColumn'] as int? ?? 1,
              ),
              end: Position(
                line: selectionMap['endLine'] as int? ?? 1,
                column: selectionMap['endColumn'] as int? ?? 1,
              ),
            )
          : null,
      scrollOffset: (json['scroll'] as num? ?? 0.0).toDouble(),
      folds: foldsList.map((f) => RecoveredFold.fromJson(f)).toList(),
      revision: json['revision'] as int? ?? 0,
      isDirty: json['dirty'] as bool? ?? false,
      buffer: json['buffer'] as String? ?? '',
    );
  }
}

class RecoveredFold {
  final int startLine;
  final int endLine;
  final bool collapsed;

  RecoveredFold({
    required this.startLine,
    required this.endLine,
    required this.collapsed,
  });

  Map<String, dynamic> toJson() => {
    'startLine': startLine,
    'endLine': endLine,
    'collapsed': collapsed,
  };

  factory RecoveredFold.fromJson(Map<String, dynamic> json) {
    return RecoveredFold(
      startLine: json['startLine'] as int? ?? 0,
      endLine: json['endLine'] as int? ?? 0,
      collapsed: json['collapsed'] as bool? ?? false,
    );
  }
}

class RecoverySession {
  static const int schemaVersion = 1;

  final int version;
  final String workspace;
  final DateTime savedAt;
  final List<RecoveredDocument> documents;
  final int activeTabIndex;

  RecoverySession({
    this.version = schemaVersion,
    required this.workspace,
    required this.savedAt,
    required this.documents,
    required this.activeTabIndex,
  });

  Map<String, dynamic> toJson() => {
    'version': version,
    'workspace': workspace,
    'savedAt': savedAt.toIso8601String(),
    'documents': documents.map((d) => d.toJson()).toList(),
    'activeTabIndex': activeTabIndex,
  };

  factory RecoverySession.fromJson(Map<String, dynamic> json) {
    final docsList = json['documents'] as List? ?? [];
    return RecoverySession(
      version: json['version'] as int? ?? schemaVersion,
      workspace: json['workspace'] as String? ?? '',
      savedAt: DateTime.tryParse(json['savedAt'] ?? '') ?? DateTime.now(),
      documents: docsList
          .map((d) => RecoveredDocument.fromJson(Map<String, dynamic>.from(d)))
          .toList(),
      activeTabIndex: json['activeTabIndex'] as int? ?? 0,
    );
  }
}

class RecoveryService {
  final String workspaceRoot;

  RecoveryService({required this.workspaceRoot});

  File get _recoveryFile => File('$workspaceRoot/.agents/recovery.json');
  File get _tempFile => File('$workspaceRoot/.agents/recovery.json.tmp');

  Future<void> save(RecoverySession session) async {
    try {
      final dir = Directory('$workspaceRoot/.agents');
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }

      final jsonStr = jsonEncode(session.toJson());
      // Atomic write
      await _tempFile.writeAsString(jsonStr, flush: true);
      if (_recoveryFile.existsSync()) {
        await _recoveryFile.delete();
      }
      await _tempFile.rename(_recoveryFile.path);
    } catch (_) {
      // Ignore write errors in read-only / locked workspaces
    }
  }

  Future<RecoverySession?> restore() async {
    try {
      if (!_recoveryFile.existsSync()) return null;
      final content = await _recoveryFile.readAsString();
      final decoded = jsonDecode(content) as Map<String, dynamic>;
      return RecoverySession.fromJson(decoded);
    } catch (_) {
      // Corrupt cache falls back cleanly to null
      return null;
    }
  }

  Future<void> clear() async {
    try {
      if (_recoveryFile.existsSync()) {
        await _recoveryFile.delete();
      }
    } catch (_) {}
  }
}
