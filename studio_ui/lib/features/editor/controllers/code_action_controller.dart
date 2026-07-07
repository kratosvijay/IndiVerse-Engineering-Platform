import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/state/studio_state.dart';
import '../../../../models/editor_document.dart';
import '../../../../models/language_intelligence_models.dart';
import '../../../../core/services/workbench_providers.dart';
import '../../../../core/services/workspace_edit_executor.dart';

class CodeActionSession {
  final String requestId;
  final int revision;
  final Position position;
  final SelectionRange selection;
  final List<CodeAction> actions;
  int selectedIndex;
  bool isVisible;

  CodeActionSession({
    required this.requestId,
    required this.revision,
    required this.position,
    required this.selection,
    required this.actions,
    this.selectedIndex = 0,
    this.isVisible = false,
  });
}

class CodeActionController {
  final StudioState state;
  CodeActionSession? activeSession;
  Timer? _debounceTimer;
  CancellationToken? _cancellationToken;
  OverlayEntry? _lightbulbOverlayEntry;
  OverlayEntry? _actionsOverlayEntry;

  double lastRequestLatencyMs = 0.0;
  bool lastRequestCacheHit = false;

  CodeActionController({required this.state});

  void triggerCodeActions({required bool isManual}) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 50), () {
      _fetchCodeActions(isManual);
    });
  }

  Future<void> _fetchCodeActions(bool isManual) async {
    final activeTab = state.editor.activeTab;
    if (activeTab == null) {
      closeSession();
      return;
    }

    final doc = activeTab.document;
    final pos = doc.cursor;
    final revision = doc.version.localRevision;
    final selStart = doc.selection?.start ?? pos;
    final selEnd = doc.selection?.end ?? pos;
    final selectionRange = SelectionRange(start: selStart, end: selEnd);

    // If manual trigger and we already have cached actions for the current position, show it immediately!
    if (isManual &&
        activeSession != null &&
        activeSession!.position == pos &&
        activeSession!.revision == revision) {
      activeSession!.isVisible = true;
      state.refreshUI();
      return;
    }

    // Diagnostics lookup
    final fileDiags = state.diagnostics.getForFile(doc.path);
    final intersecting = fileDiags
        .where((d) => _rangeOverlaps(d.range, selectionRange))
        .toList();

    _cancellationToken?.cancel();
    final token = CancellationToken();
    _cancellationToken = token;

    final languageCtx = LanguageContext(
      document: doc,
      position: pos,
      workspace: state.activeProject,
      workspaceRevision: 0,
      token: token,
    );

    final diagnosticIds = intersecting.map((d) => d.id).toList();

    final stopwatch = Stopwatch()..start();
    final cacheHitsBefore = state.languageIntel.codeActionCacheHits;

    final result = await state.languageIntel.getCodeActions(
      languageCtx,
      diagnosticIds,
    );
    stopwatch.stop();

    if (token.isCancelled) return;

    lastRequestLatencyMs = stopwatch.elapsedMilliseconds.toDouble();
    lastRequestCacheHit =
        state.languageIntel.codeActionCacheHits > cacheHitsBefore;

    if (!result.success || result.data == null || result.data!.isEmpty) {
      // If we are dart, we might still have Organize Imports even if no diagnostics
      final actions = result.data ?? [];
      if (actions.isEmpty) {
        closeSession();
        return;
      }
    }

    final actions = result.data!;
    activeSession = CodeActionSession(
      requestId: 'code-action-session-${DateTime.now().millisecondsSinceEpoch}',
      revision: revision,
      position: pos,
      selection: selectionRange,
      actions: actions,
      isVisible: isManual,
    );

    state.refreshUI();
  }

  Future<void> executeSelectedAction() async {
    final session = activeSession;
    if (session == null ||
        session.selectedIndex < 0 ||
        session.selectedIndex >= session.actions.length) {
      return;
    }

    final action = session.actions[session.selectedIndex];
    closeSession();

    if (action.edit != null) {
      final startTime = DateTime.now();
      final executor = WorkspaceEditExecutor(state: state);
      final res = await executor.execute(
        action.edit!,
        expectedRevision: session.revision,
      );
      final elapsed = DateTime.now().difference(startTime);

      if (res.success) {
        state.languageIntel.recordAppliedAction(action.kind.value, elapsed);
      } else {
        state.languageIntel.recordFailedAction(action.kind.value);
      }
    }
  }

  Future<void> executeAction(CodeAction action) async {
    final session = activeSession;
    closeSession();

    if (action.edit != null) {
      final startTime = DateTime.now();
      final executor = WorkspaceEditExecutor(state: state);
      final res = await executor.execute(
        action.edit!,
        expectedRevision: session?.revision,
      );
      final elapsed = DateTime.now().difference(startTime);

      if (res.success) {
        state.languageIntel.recordAppliedAction(action.kind.value, elapsed);
      } else {
        state.languageIntel.recordFailedAction(action.kind.value);
      }
    }
  }

  void closeSession() {
    _debounceTimer?.cancel();
    _cancellationToken?.cancel();
    _cancellationToken = null;
    activeSession = null;
    hideOverlays();
    state.refreshUI();
  }

  void updateLightbulbOverlay(OverlayEntry? entry) {
    _lightbulbOverlayEntry?.remove();
    _lightbulbOverlayEntry = entry;
  }

  void updateActionsOverlay(OverlayEntry? entry) {
    _actionsOverlayEntry?.remove();
    _actionsOverlayEntry = entry;
  }

  void hideOverlays() {
    _lightbulbOverlayEntry?.remove();
    _lightbulbOverlayEntry = null;
    _actionsOverlayEntry?.remove();
    _actionsOverlayEntry = null;
  }

  bool _rangeOverlaps(SelectionRange r1, SelectionRange r2) {
    if (_comparePosition(r1.end, r2.start) < 0) return false;
    if (_comparePosition(r2.end, r1.start) < 0) return false;
    return true;
  }

  int _comparePosition(Position p1, Position p2) {
    if (p1.line != p2.line) return p1.line.compareTo(p2.line);
    return p1.column.compareTo(p2.column);
  }
}
