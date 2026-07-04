import '../../../models/editor_document.dart';
import '../../../models/edit_operation.dart';
import '../../../core/services/language_editing_strategy.dart';
import '../../../core/services/workbench_providers.dart';
import '../../../core/services/document_history_service.dart';

class EditorController {
  final List<EditorTab> tabs = [];
  int activeTabIndex = -1;
  final List<EditorTab> _closedTabsHistory = [];

  EditorTab? get activeTab =>
      activeTabIndex >= 0 && activeTabIndex < tabs.length
      ? tabs[activeTabIndex]
      : null;

  void open(EditorDocument doc) {
    final existingIndex = tabs.indexWhere((t) => t.document.path == doc.path);
    if (existingIndex != -1) {
      activeTabIndex = existingIndex;
    } else {
      tabs.add(EditorTab(document: doc));
      activeTabIndex = tabs.length - 1;
    }
  }

  void close(int index) {
    if (index >= 0 && index < tabs.length) {
      final closed = tabs.removeAt(index);
      _closedTabsHistory.add(closed);
      if (activeTabIndex >= tabs.length) {
        activeTabIndex = tabs.length - 1;
      }
    }
  }

  void activate(int index) {
    if (index >= 0 && index < tabs.length) {
      activeTabIndex = index;
    }
  }

  void reopenLastClosed() {
    if (_closedTabsHistory.isNotEmpty) {
      final tab = _closedTabsHistory.removeLast();
      open(tab.document);
    }
  }

  void closeOthers(int index) {
    if (index >= 0 && index < tabs.length) {
      final keeper = tabs[index];
      tabs.clear();
      tabs.add(keeper);
      activeTabIndex = 0;
    }
  }

  void closeAll() {
    tabs.clear();
    activeTabIndex = -1;
  }

  Future<OperationResult<void>> commentLine(
    EditorDocument doc,
    DocumentHistoryService history,
  ) async {
    final strategy = LanguageEditingStrategyRegistry.getStrategy(doc.language);
    final prefix = strategy.lineCommentPrefix;
    if (prefix.isEmpty) return const OperationResult.ok(null);

    final selection = doc.selection;
    final int startLine = selection?.start.line ?? doc.cursorLine;
    final int endLine = selection?.end.line ?? doc.cursorLine;

    final startOffset = doc.positionToOffset(
      Position(line: startLine, column: 1),
    );
    final endOffset = doc.positionToOffset(
      Position(line: endLine, column: doc.lines[endLine - 1].length + 1),
    );
    final oldText = doc.lines.sublist(startLine - 1, endLine).join('\n');

    bool allCommented = true;
    for (int i = startLine; i <= endLine; i++) {
      final line = doc.lines[i - 1];
      if (line.trim().isNotEmpty && !line.trim().startsWith(prefix)) {
        allCommented = false;
        break;
      }
    }

    final newLines = <String>[];
    for (int i = startLine; i <= endLine; i++) {
      final line = doc.lines[i - 1];
      if (allCommented) {
        if (line.trim().startsWith(prefix)) {
          final firstPrefixIdx = line.indexOf(prefix);
          final updated =
              line.substring(0, firstPrefixIdx) +
              line.substring(firstPrefixIdx + prefix.length);
          newLines.add(updated);
        } else {
          newLines.add(line);
        }
      } else {
        final leadingSpaces = line.length - line.trimLeft().length;
        final updated =
            line.substring(0, leadingSpaces) +
            prefix +
            ' ' +
            line.substring(leadingSpaces);
        newLines.add(updated);
      }
    }
    final newText = newLines.join('\n');

    final op = ReplaceTextOperation(
      index: startOffset,
      oldText: oldText,
      newText: newText,
    );

    final context = OperationContext(
      timestamp: DateTime.now(),
      source: "command",
    );
    final res = await op.apply(doc, context);
    if (res.success) {
      history.recordOperation(doc.id, op);
    }
    return res;
  }

  Future<OperationResult<void>> duplicateLine(
    EditorDocument doc,
    DocumentHistoryService history,
  ) async {
    final selection = doc.selection;
    final int startLine = selection?.start.line ?? doc.cursorLine;
    final int endLine = selection?.end.line ?? doc.cursorLine;

    final linesText = doc.lines.sublist(startLine - 1, endLine).join('\n');
    final insertOffset = doc.positionToOffset(
      Position(line: endLine, column: doc.lines[endLine - 1].length + 1),
    );

    final op = InsertTextOperation(index: insertOffset, text: '\n' + linesText);

    final context = OperationContext(
      timestamp: DateTime.now(),
      source: "command",
    );
    final res = await op.apply(doc, context);
    if (res.success) {
      history.recordOperation(doc.id, op);
    }
    return res;
  }

  Future<OperationResult<void>> deleteLine(
    EditorDocument doc,
    DocumentHistoryService history,
  ) async {
    final selection = doc.selection;
    final int startLine = selection?.start.line ?? doc.cursorLine;
    final int endLine = selection?.end.line ?? doc.cursorLine;

    final startOffset = doc.positionToOffset(
      Position(line: startLine, column: 1),
    );
    int endOffset;
    if (endLine < doc.lineCount) {
      endOffset = doc.positionToOffset(Position(line: endLine + 1, column: 1));
    } else {
      endOffset = doc.size;
    }

    final length = endOffset - startOffset;
    if (length <= 0) return const OperationResult.ok(null);

    final deletedText = doc.content.substring(startOffset, endOffset);
    final op = DeleteTextOperation(index: startOffset, text: deletedText);

    final context = OperationContext(
      timestamp: DateTime.now(),
      source: "command",
    );
    final res = await op.apply(doc, context);
    if (res.success) {
      history.recordOperation(doc.id, op);
    }
    return res;
  }

  Future<OperationResult<void>> moveLineUp(
    EditorDocument doc,
    DocumentHistoryService history,
  ) async {
    final selection = doc.selection;
    final int startLine = selection?.start.line ?? doc.cursorLine;
    final int endLine = selection?.end.line ?? doc.cursorLine;

    if (startLine <= 1) return const OperationResult.ok(null);

    final lineAboveText = doc.lines[startLine - 2];
    final blockText = doc.lines.sublist(startLine - 1, endLine).join('\n');

    final startOffset = doc.positionToOffset(
      Position(line: startLine - 1, column: 1),
    );
    final blockEndOffset = doc.positionToOffset(
      Position(line: endLine, column: doc.lines[endLine - 1].length + 1),
    );
    final originalText = doc.content.substring(startOffset, blockEndOffset);
    final updatedText = blockText + '\n' + lineAboveText;

    final op = ReplaceTextOperation(
      index: startOffset,
      oldText: originalText,
      newText: updatedText,
    );

    final context = OperationContext(
      timestamp: DateTime.now(),
      source: "command",
    );
    final res = await op.apply(doc, context);
    if (res.success) {
      history.recordOperation(doc.id, op);
      doc.updateCursor(Position(line: startLine - 1, column: doc.cursorColumn));
    }
    return res;
  }

  Future<OperationResult<void>> moveLineDown(
    EditorDocument doc,
    DocumentHistoryService history,
  ) async {
    final selection = doc.selection;
    final int startLine = selection?.start.line ?? doc.cursorLine;
    final int endLine = selection?.end.line ?? doc.cursorLine;

    if (endLine >= doc.lineCount) return const OperationResult.ok(null);

    final lineBelowText = doc.lines[endLine];
    final blockText = doc.lines.sublist(startLine - 1, endLine).join('\n');

    final startOffset = doc.positionToOffset(
      Position(line: startLine, column: 1),
    );
    final blockEndOffset = doc.positionToOffset(
      Position(line: endLine + 1, column: doc.lines[endLine].length + 1),
    );
    final originalText = doc.content.substring(startOffset, blockEndOffset);
    final updatedText = lineBelowText + '\n' + blockText;

    final op = ReplaceTextOperation(
      index: startOffset,
      oldText: originalText,
      newText: updatedText,
    );

    final context = OperationContext(
      timestamp: DateTime.now(),
      source: "command",
    );
    final res = await op.apply(doc, context);
    if (res.success) {
      history.recordOperation(doc.id, op);
      doc.updateCursor(Position(line: startLine + 1, column: doc.cursorColumn));
    }
    return res;
  }

  void selectAll(EditorDocument doc) {
    final start = const Position(line: 1, column: 1);
    final end = Position(
      line: doc.lineCount,
      column: doc.lines.last.length + 1,
    );
    doc.updateSelection(SelectionRange(start: start, end: end));
  }
}
