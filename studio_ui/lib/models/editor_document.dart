import 'package:flutter/material.dart';
import 'folding_region.dart';
import '../features/editor/controllers/folding_provider.dart';

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

  factory Position.fromJson(Map<String, dynamic> json) {
    return Position(
      line: json['line'] as int? ?? 1,
      column: json['column'] as int? ?? 1,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Position &&
          runtimeType == other.runtimeType &&
          line == other.line &&
          column == other.column;

  @override
  int get hashCode => line.hashCode ^ column.hashCode;
}

class SelectionRange {
  final Position start;
  final Position end;

  const SelectionRange({required this.start, required this.end});

  bool get isEmpty => start.line == end.line && start.column == end.column;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SelectionRange &&
          runtimeType == other.runtimeType &&
          start == other.start &&
          end == other.end;

  @override
  int get hashCode => start.hashCode ^ end.hashCode;
}

class DocumentSnapshot {
  final int revision;
  final List<String> lines;

  DocumentSnapshot({required this.revision, required List<String> lines})
    : lines = List.unmodifiable(lines);
}

enum AutoSavePolicy { manual, never, afterDelay, onFocusLost, onWindowClose }

enum DocumentLockReason {
  saving,
  readOnly,
  conflict,
  recovering,
  deleting,
  renaming,
}

class EditorDocument extends ChangeNotifier {
  final String id;
  final String path;
  final String name;
  final List<String> _lines;
  final String language;
  final String encoding;
  final String lastModified;
  final bool readOnly;

  DocumentState state = DocumentState.clean;
  DocumentLockReason? _explicitLockReason;

  DocumentLockReason? get lockReason {
    if (_explicitLockReason != null) return _explicitLockReason;
    switch (state) {
      case DocumentState.saving:
        return DocumentLockReason.saving;
      case DocumentState.readOnly:
        return DocumentLockReason.readOnly;
      case DocumentState.conflict:
        return DocumentLockReason.conflict;
      default:
        return null;
    }
  }

  set lockReason(DocumentLockReason? val) {
    _explicitLockReason = val;
    notifyListeners();
  }

  DocumentVersion version = DocumentVersion(
    localRevision: 0,
    savedAt: DateTime.now(),
  );

  Position cursor = const Position(line: 1, column: 1);
  SelectionRange? selection;

  double scrollOffset = 0.0;

  List<FoldingRegion> foldingRegions = [];
  final Map<int, FoldingRegion> foldingLookup = {};

  int get cursorLine => cursor.line;
  int get cursorColumn => cursor.column;

  EditorDocument({
    required this.id,
    required this.path,
    required this.name,
    required String content,
    required this.language,
    required this.encoding,
    required this.lastModified,
    required this.readOnly,
  }) : _lines = content.split('\n') {
    _reparseFoldingRegions();
  }

  String get content => _lines.join('\n');
  List<String> get lines => List.unmodifiable(_lines);
  int get lineCount => _lines.length;
  int get size => content.length;

  FoldingProvider _resolveFoldingProvider() {
    switch (language.toLowerCase()) {
      case 'dart':
        return DartFoldingProvider();
      case 'json':
        return JsonFoldingProvider();
      case 'yaml':
        return YamlFoldingProvider();
      case 'markdown':
        return MarkdownFoldingProvider();
      default:
        return BracketFoldingProvider();
    }
  }

  void _reparseFoldingRegions() {
    final provider = _resolveFoldingProvider();
    final newRoots = provider.build(this);

    final List<FoldingRegion> oldFlat = [];
    for (final r in foldingRegions) {
      oldFlat.addAll(r.toFlatList());
    }

    final Map<String, FoldingRegion> oldBySig = {
      for (final r in oldFlat) r.signature: r,
    };

    List<FoldingRegion> mergeState(List<FoldingRegion> regions) {
      return regions.map((region) {
        bool collapsed = false;

        final matchedSig = oldBySig[region.signature];
        if (matchedSig != null) {
          collapsed = matchedSig.collapsed;
        } else {
          final proximityMatch = oldFlat.firstWhere(
            (r) =>
                r.signature.split('@').first ==
                    region.signature.split('@').first &&
                (r.startLine - region.startLine).abs() <= 10,
            orElse: () =>
                const FoldingRegion(startLine: -1, endLine: -1, signature: ''),
          );
          if (proximityMatch.startLine != -1) {
            collapsed = proximityMatch.collapsed;
          } else {
            final lengthMatch = oldFlat.firstWhere(
              (r) =>
                  r.startLine == region.startLine &&
                  (r.endLine -
                              r.startLine -
                              (region.endLine - region.startLine))
                          .abs() <=
                      5,
              orElse: () => const FoldingRegion(
                startLine: -1,
                endLine: -1,
                signature: '',
              ),
            );
            if (lengthMatch.startLine != -1) {
              collapsed = lengthMatch.collapsed;
            }
          }
        }

        final List<FoldingRegion> mergedChildren = mergeState(region.children);
        return region.copyWith(collapsed: collapsed, children: mergedChildren);
      }).toList();
    }

    foldingRegions = mergeState(newRoots);
    _rebuildFoldingLookup();
  }

  void _rebuildFoldingLookup() {
    foldingLookup.clear();
    final List<FoldingRegion> flat = [];
    for (final r in foldingRegions) {
      flat.addAll(r.toFlatList());
    }
    for (final r in flat) {
      foldingLookup[r.startLine] = r;
    }
  }

  void reparseFolding() {
    _reparseFoldingRegions();
  }

  void replaceBuffer(String newContent) {
    _lines.clear();
    _lines.addAll(newContent.split('\n'));
    version = DocumentVersion(
      localRevision: version.localRevision + 1,
      savedAt: DateTime.now(),
    );
    _reparseFoldingRegions();
    notifyListeners();
  }

  void toggleFold(int line) {
    final region = foldingLookup[line];
    if (region != null) {
      _updateRegionCollapsed(foldingRegions, line, !region.collapsed);
      _rebuildFoldingLookup();
      notifyListeners();
    }
  }

  void expand(int line) {
    final region = foldingLookup[line];
    if (region != null && region.collapsed) {
      _updateRegionCollapsed(foldingRegions, line, false);
      _rebuildFoldingLookup();
      notifyListeners();
    }
  }

  void collapse(int line) {
    final region = foldingLookup[line];
    if (region != null && !region.collapsed) {
      _updateRegionCollapsed(foldingRegions, line, true);
      _rebuildFoldingLookup();
      notifyListeners();
    }
  }

  bool _updateRegionCollapsed(
    List<FoldingRegion> list,
    int line,
    bool collapsed,
  ) {
    for (int i = 0; i < list.length; i++) {
      final r = list[i];
      if (r.startLine == line) {
        list[i] = r.copyWith(collapsed: collapsed);
        return true;
      }
      final List<FoldingRegion> updatedChildren = List.from(r.children);
      if (_updateRegionCollapsed(updatedChildren, line, collapsed)) {
        list[i] = r.copyWith(children: updatedChildren);
        return true;
      }
    }
    return false;
  }

  void expandAll() {
    void expandNode(List<FoldingRegion> list) {
      for (int i = 0; i < list.length; i++) {
        final r = list[i];
        final List<FoldingRegion> children = List.from(r.children);
        expandNode(children);
        list[i] = r.copyWith(collapsed: false, children: children);
      }
    }

    expandNode(foldingRegions);
    _rebuildFoldingLookup();
    notifyListeners();
  }

  void collapseAll() {
    void collapseNode(List<FoldingRegion> list) {
      for (int i = 0; i < list.length; i++) {
        final r = list[i];
        final List<FoldingRegion> children = List.from(r.children);
        collapseNode(children);
        list[i] = r.copyWith(collapsed: true, children: children);
      }
    }

    collapseNode(foldingRegions);
    _rebuildFoldingLookup();
    notifyListeners();
  }

  Position offsetToPosition(int offset) {
    if (offset <= 0) return const Position(line: 1, column: 1);

    int currentOffset = 0;
    for (int i = 0; i < _lines.length; i++) {
      final line = _lines[i];
      final lineLength = line.length + 1; // +1 for the newline character '\n'
      if (currentOffset + lineLength > offset) {
        return Position(line: i + 1, column: offset - currentOffset + 1);
      }
      currentOffset += lineLength;
    }

    return Position(line: _lines.length, column: _lines.last.length + 1);
  }

  int positionToOffset(Position pos) {
    int offset = 0;
    final targetLine = pos.line.clamp(1, _lines.length);
    for (int i = 0; i < targetLine - 1; i++) {
      offset += _lines[i].length + 1; // +1 for '\n'
    }
    final targetLineText = _lines[targetLine - 1];
    final targetCol = pos.column.clamp(1, targetLineText.length + 1);
    offset += targetCol - 1;
    return offset;
  }

  DocumentSnapshot createSnapshot() {
    return DocumentSnapshot(revision: version.localRevision, lines: _lines);
  }

  void updateContentInternal(String newContent) {
    if (readOnly) return;
    _lines.clear();
    _lines.addAll(newContent.split('\n'));
    state = DocumentState.dirty;
    version = DocumentVersion(
      localRevision: version.localRevision + 1,
      savedAt: version.savedAt,
    );
    _reparseFoldingRegions();
    notifyListeners();
  }

  void updateLinesInternal(List<String> newLines) {
    if (readOnly) return;
    _lines.clear();
    _lines.addAll(newLines);
    state = DocumentState.dirty;
    version = DocumentVersion(
      localRevision: version.localRevision + 1,
      savedAt: version.savedAt,
    );
    _reparseFoldingRegions();
    notifyListeners();
  }

  void insertTextAtPosition(Position pos, String text) {
    if (readOnly) return;
    final targetLine = pos.line.clamp(1, _lines.length);
    final lineText = _lines[targetLine - 1];
    final targetCol = pos.column.clamp(1, lineText.length + 1);

    final prefix = lineText.substring(0, targetCol - 1);
    final suffix = lineText.substring(targetCol - 1);

    final newParts = text.split('\n');
    Position endCursor;
    if (newParts.length == 1) {
      _lines[targetLine - 1] = prefix + text + suffix;
      endCursor = Position(line: targetLine, column: targetCol + text.length);
    } else {
      _lines[targetLine - 1] = prefix + newParts.first;
      for (int i = 1; i < newParts.length - 1; i++) {
        _lines.insert(targetLine - 1 + i, newParts[i]);
      }
      _lines.insert(targetLine - 2 + newParts.length, newParts.last + suffix);
      endCursor = Position(
        line: targetLine + newParts.length - 1,
        column: newParts.last.length + 1,
      );
    }

    state = DocumentState.dirty;
    version = DocumentVersion(
      localRevision: version.localRevision + 1,
      savedAt: version.savedAt,
    );
    cursor = endCursor;
    _reparseFoldingRegions();
    notifyListeners();
  }

  void deleteTextBetweenPositions(Position startPos, Position endPos) {
    if (readOnly) return;
    final sLine = startPos.line.clamp(1, _lines.length);
    final sText = _lines[sLine - 1];
    final sCol = startPos.column.clamp(1, sText.length + 1);

    final eLine = endPos.line.clamp(1, _lines.length);
    final eText = _lines[eLine - 1];
    final eCol = endPos.column.clamp(1, eText.length + 1);

    final prefix = sText.substring(0, sCol - 1);
    final suffix = eText.substring(eCol - 1);

    if (sLine == eLine) {
      _lines[sLine - 1] = prefix + suffix;
    } else {
      _lines[sLine - 1] = prefix + suffix;
      _lines.removeRange(sLine, eLine);
    }

    state = DocumentState.dirty;
    version = DocumentVersion(
      localRevision: version.localRevision + 1,
      savedAt: version.savedAt,
    );
    cursor = startPos;
    _reparseFoldingRegions();
    notifyListeners();
  }

  void insertTextAtOffset(int offset, String text) {
    final pos = offsetToPosition(offset);
    insertTextAtPosition(pos, text);
  }

  void deleteTextAtOffset(int offset, int length) {
    final start = offsetToPosition(offset);
    final end = offsetToPosition(offset + length);
    deleteTextBetweenPositions(start, end);
  }

  void updateCursor(Position newCursor) {
    cursor = newCursor;
    notifyListeners();
  }

  void updateSelection(SelectionRange? newSelection) {
    selection = newSelection;
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
