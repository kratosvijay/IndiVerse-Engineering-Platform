import 'package:flutter/material.dart';

enum DocumentState { clean, dirty, saving, conflict, readOnly }

class DocumentVersion {
  final int localRevision;
  final DateTime savedAt;

  const DocumentVersion({required this.localRevision, required this.savedAt});
}

class Position {
  final int line;
  final int column;

  const Position({required this.line, required this.column});
}

class Cursor {
  final Position position;

  const Cursor({required this.position});
}

class TextSelectionRange {
  final Position start;
  final Position end;

  const TextSelectionRange({required this.start, required this.end});
}

enum AutoSavePolicy { never, afterDelay, onFocusLost, onWindowClose, manual }

class EditorDocument extends ChangeNotifier {
  final String id;
  final String path;
  final String name;
  String _content;
  final String language;
  final String encoding;
  final String lastModified;
  final bool readOnly;

  DocumentState state = DocumentState.clean;
  DocumentVersion version = DocumentVersion(
    localRevision: 0,
    savedAt: DateTime.now(),
  );
  Cursor cursor = const Cursor(position: Position(line: 1, column: 1));
  TextSelectionRange? selection;

  // Session UI states
  int cursorLine = 1;
  int cursorColumn = 1;
  double scrollOffset = 0.0;

  EditorDocument({
    required this.id,
    required this.path,
    required this.name,
    required String content,
    required this.language,
    required this.encoding,
    required this.lastModified,
    required this.readOnly,
  }) : _content = content;

  String get content => _content;
  int get lineCount => _content.split('\n').length;
  int get size => _content.length;

  void updateContentInternal(String newContent) {
    if (readOnly) return;
    _content = newContent;
    state = DocumentState.dirty;
    version = DocumentVersion(
      localRevision: version.localRevision + 1,
      savedAt: version.savedAt,
    );
    notifyListeners();
  }

  void markSaved(DateTime time) {
    state = DocumentState.clean;
    version = DocumentVersion(
      localRevision: version.localRevision,
      savedAt: time,
    );
    notifyListeners();
  }
}

class EditorTab {
  final EditorDocument document;

  EditorTab({required this.document});
}
