
class EditorDocument {
  final String id;
  final String path;
  final String name;
  final String content;
  final String language;
  final String encoding;
  final int lineCount;
  final int size;
  final String lastModified;
  final bool readOnly;
  
  // Session UI states
  int cursorLine = 1;
  int cursorColumn = 1;
  double scrollOffset = 0.0;
  bool isDirty = false;

  EditorDocument({
    required this.id,
    required this.path,
    required this.name,
    required this.content,
    required this.language,
    required this.encoding,
    required this.lineCount,
    required this.size,
    required this.lastModified,
    required this.readOnly,
  });
}

class EditorTab {
  final EditorDocument document;
  
  EditorTab({required this.document});
}
