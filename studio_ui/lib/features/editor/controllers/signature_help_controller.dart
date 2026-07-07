import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/state/studio_state.dart';
import '../../../../models/editor_document.dart';
import '../../../../models/language_intelligence_models.dart';
import '../../../../core/services/workbench_providers.dart';

class SignatureSession {
  final String sessionId;
  final String requestId;
  final Position anchorPosition;
  final Position currentPosition;
  final int activeSignature;
  final int activeParameter;
  final int revision;
  final SignatureTriggerKind triggerKind;
  final SignatureHelp help;

  SignatureSession({
    required this.sessionId,
    required this.requestId,
    required this.anchorPosition,
    required this.currentPosition,
    required this.activeSignature,
    required this.activeParameter,
    required this.revision,
    required this.triggerKind,
    required this.help,
  });
}

class SignatureHelpController {
  final StudioState state;
  SignatureSession? activeSession;
  Timer? _debounceTimer;
  CancellationToken? _cancellationToken;
  OverlayEntry? _overlayEntry;
  bool isOverlayVisible = false;

  double lastRequestLatencyMs = 0.0;
  bool lastRequestCacheHit = false;

  SignatureHelpController({required this.state});

  void triggerSignatureHelp(SignatureTriggerKind triggerKind) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 50), () {
      _fetchSignatureHelp(triggerKind);
    });
  }

  Future<void> _fetchSignatureHelp(SignatureTriggerKind triggerKind) async {
    final activeTab = state.editor.activeTab;
    if (activeTab == null) return;

    final doc = activeTab.document;
    final pos = doc.cursor;
    final revision = doc.version.localRevision;

    final Position anchor = activeSession?.anchorPosition ?? pos;

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

    final stopwatch = Stopwatch()..start();
    final cacheHitsBefore = state.languageIntel.signatureCacheHits;

    final result = await state.languageIntel.getSignatureHelp(
      languageCtx,
      triggerKind,
    );
    stopwatch.stop();

    if (token.isCancelled) return;

    lastRequestLatencyMs = stopwatch.elapsedMilliseconds.toDouble();
    lastRequestCacheHit =
        state.languageIntel.signatureCacheHits > cacheHitsBefore;

    if (!result.success ||
        result.data == null ||
        result.data!.signatures.isEmpty) {
      closeSession();
      return;
    }

    final help = result.data!;

    if (pos.line != anchor.line || pos.column < anchor.column) {
      closeSession();
      return;
    }

    final sId =
        activeSession?.sessionId ??
        'sig-session-${DateTime.now().millisecondsSinceEpoch}';
    final rId = 'sig-req-${DateTime.now().millisecondsSinceEpoch}';

    activeSession = SignatureSession(
      sessionId: sId,
      requestId: rId,
      anchorPosition: anchor,
      currentPosition: pos,
      activeSignature: help.activeSignature,
      activeParameter: help.activeParameter,
      revision: revision,
      triggerKind: triggerKind,
      help: help,
    );

    isOverlayVisible = true;
    state.refreshUI();
  }

  void closeSession() {
    _debounceTimer?.cancel();
    _cancellationToken?.cancel();
    _cancellationToken = null;
    activeSession = null;
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
