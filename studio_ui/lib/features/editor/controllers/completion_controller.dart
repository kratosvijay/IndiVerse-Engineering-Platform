import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/state/studio_state.dart';
import '../../../../models/editor_document.dart';
import '../../../../models/edit_operation.dart';
import '../../../../models/language_intelligence_models.dart';
import '../../../../models/completion_session.dart';
import '../../../../core/services/completion_ranker.dart';
import '../../../../core/services/workbench_providers.dart';

class CompletionController {
  final StudioState state;
  CompletionSession? activeSession;
  Timer? _debounceTimer;
  OverlayEntry? _overlayEntry;
  bool isOverlayVisible = false;

  double lastRequestLatencyMs = 0.0;
  bool lastRequestCacheHit = false;

  CompletionController({required this.state});

  void triggerCompletion(CompletionTrigger trigger) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 50), () {
      _fetchCompletions(trigger);
    });
  }

  Future<void> _fetchCompletions(CompletionTrigger trigger) async {
    final activeTab = state.editor.activeTab;
    if (activeTab == null) return;

    final doc = activeTab.document;
    final pos = doc.cursor;
    final revision = doc.version.localRevision;

    final languageCtx = LanguageContext(
      document: doc,
      position: pos,
      workspace: "",
      workspaceRevision: 0,
      token: CancellationToken(),
    );

    final stopwatch = Stopwatch()..start();
    final cacheHitsBefore = state.intelligence.completionCacheHits;

    final result = await state.intelligence.getCompletions(
      languageCtx,
      trigger,
    );
    stopwatch.stop();

    lastRequestLatencyMs = stopwatch.elapsedMilliseconds.toDouble();
    lastRequestCacheHit =
        state.intelligence.completionCacheHits > cacheHitsBefore;

    if (!result.success || result.data == null) {
      closeSession();
      return;
    }

    final rawItems = result.data!;
    if (rawItems.isEmpty) {
      closeSession();
      return;
    }

    // 1. Calculate prefix for scoring
    String prefix = '';
    try {
      final lineContent = doc.lines[pos.line - 1];
      final col = pos.column - 1;
      if (col > 0 && col <= lineContent.length) {
        int start = col - 1;
        while (start >= 0) {
          final c = lineContent[start];
          if (RegExp(r'[a-zA-Z0-9_]').hasMatch(c)) {
            start--;
          } else {
            break;
          }
        }
        prefix = lineContent.substring(start + 1, col);
      }
    } catch (_) {}

    // 2. Rank and filter suggestions
    final ranked = CompletionRanker.rank(rawItems, prefix);
    if (ranked.isEmpty) {
      closeSession();
      return;
    }

    final sessionId = 'session-${DateTime.now().millisecondsSinceEpoch}';
    activeSession = CompletionSession(
      id: sessionId,
      anchor: pos,
      documentRevision: revision,
      trigger: trigger,
      items: ranked,
      selectedIndex: 0,
    );

    isOverlayVisible = true;
    state.refreshUI();
  }

  void filterSession() {
    final session = activeSession;
    if (session == null || !session.isActive) return;

    final activeTab = state.editor.activeTab;
    if (activeTab == null) {
      closeSession();
      return;
    }

    final doc = activeTab.document;
    final pos = doc.cursor;

    // Check if cursor moved away from the anchor line
    if (pos.line != session.anchor.line || pos.column < session.anchor.column) {
      closeSession();
      return;
    }

    // Recalculate prefix relative to anchor position
    String prefix = '';
    try {
      final lineContent = doc.lines[pos.line - 1];
      final start = session.anchor.column - 1;
      final end = pos.column - 1;
      if (end >= start && end <= lineContent.length) {
        prefix = lineContent.substring(start, end);
      }
    } catch (_) {}

    final ranked = CompletionRanker.rank(session.items, prefix);
    if (ranked.isEmpty) {
      closeSession();
      return;
    }

    // Update active session suggestions
    activeSession = CompletionSession(
      id: session.id,
      anchor: session.anchor,
      documentRevision: doc.version.localRevision,
      trigger: session.trigger,
      items: ranked,
      selectedIndex: 0,
    );

    state.refreshUI();
  }

  void selectNext() {
    final session = activeSession;
    if (session == null || session.items.isEmpty) return;
    session.selectedIndex = (session.selectedIndex + 1) % session.items.length;
    state.refreshUI();
  }

  void selectPrevious() {
    final session = activeSession;
    if (session == null || session.items.isEmpty) return;
    session.selectedIndex =
        (session.selectedIndex - 1 + session.items.length) %
        session.items.length;
    state.refreshUI();
  }

  void selectPageDown() {
    final session = activeSession;
    if (session == null || session.items.isEmpty) return;
    session.selectedIndex = (session.selectedIndex + 5).clamp(
      0,
      session.items.length - 1,
    );
    state.refreshUI();
  }

  void selectPageUp() {
    final session = activeSession;
    if (session == null || session.items.isEmpty) return;
    session.selectedIndex = (session.selectedIndex - 5).clamp(
      0,
      session.items.length - 1,
    );
    state.refreshUI();
  }

  void selectHome() {
    final session = activeSession;
    if (session == null || session.items.isEmpty) return;
    session.selectedIndex = 0;
    state.refreshUI();
  }

  void selectEnd() {
    final session = activeSession;
    if (session == null || session.items.isEmpty) return;
    session.selectedIndex = session.items.length - 1;
    state.refreshUI();
  }

  Future<bool> commitActive() async {
    final session = activeSession;
    if (session == null ||
        session.items.isEmpty ||
        session.selectedIndex >= session.items.length) {
      return false;
    }

    final item = session.items[session.selectedIndex];
    closeSession();

    final activeTab = state.editor.activeTab;
    if (activeTab == null) return false;
    final doc = activeTab.document;

    // Calculate prefix to replace
    final pos = doc.cursor;
    String prefix = '';
    try {
      final lineContent = doc.lines[pos.line - 1];
      final col = pos.column - 1;
      if (col > 0 && col <= lineContent.length) {
        int start = col - 1;
        while (start >= 0) {
          final c = lineContent[start];
          if (RegExp(r'[a-zA-Z0-9_]').hasMatch(c)) {
            start--;
          } else {
            break;
          }
        }
        prefix = lineContent.substring(start + 1, col);
      }
    } catch (_) {}

    // 1. Calculate main TextEdit replace range
    SelectionRange replaceRange;
    if (item.textEdit != null) {
      replaceRange = item.textEdit!.range;
    } else {
      final startCol = (pos.column - prefix.length).clamp(1, pos.column);
      replaceRange = SelectionRange(
        start: Position(line: pos.line, column: startCol),
        end: pos,
      );
    }

    // 2. Perform snippet expansion if needed
    String cleanText = item.insertText;
    if (item.insertTextFormat == 2) {
      // Strip placeholders: ${1:text} -> text, $0 -> empty
      cleanText = cleanText.replaceAll(RegExp(r'\$\{\d+:([^\}]+)\}'), r'\1');
      cleanText = cleanText.replaceAll(RegExp(r'\$\d+'), '');
    }

    final startOffset = doc.positionToOffset(replaceRange.start);
    final endOffset = doc.positionToOffset(replaceRange.end);
    final oldText = doc.lines.join('\n').substring(startOffset, endOffset);

    // 3. Create & Apply main Replace Operation
    final op = ReplaceTextOperation(
      index: startOffset,
      oldText: oldText,
      newText: cleanText,
    );

    final context = OperationContext(
      timestamp: DateTime.now(),
      source: "completion",
    );

    final res = await op.apply(doc, context);
    if (res.success) {
      state.history.recordOperation(doc.id, op);

      // 4. Handle additional edits if provided
      if (item.additionalTextEdits != null) {
        for (final edit in item.additionalTextEdits!) {
          final editStart = doc.positionToOffset(edit.range.start);
          final editEnd = doc.positionToOffset(edit.range.end);
          final editOld = doc.lines.join('\n').substring(editStart, editEnd);
          final editOp = ReplaceTextOperation(
            index: editStart,
            oldText: editOld,
            newText: edit.newText,
          );
          await editOp.apply(doc, context);
          state.history.recordOperation(doc.id, editOp);
        }
      }

      // Update cursor position to end of insertion
      final newOffset = startOffset + cleanText.length;
      doc.updateCursor(doc.offsetToPosition(newOffset));
      doc.updateSelection(null);

      state.refreshUI();
      return true;
    }

    return false;
  }

  void closeSession() {
    _debounceTimer?.cancel();
    if (activeSession != null) {
      activeSession!.isActive = false;
      activeSession = null;
    }
    isOverlayVisible = false;
    state.refreshUI();
  }

  void updateOverlay(OverlayEntry? entry) {
    _overlayEntry = entry;
  }

  void hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}
