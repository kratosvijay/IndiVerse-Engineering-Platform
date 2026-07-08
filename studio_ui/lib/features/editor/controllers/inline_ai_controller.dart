import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/state/studio_state.dart';
import '../../../core/services/workspace_edit_executor.dart';
import '../../../models/editor_document.dart';
import '../../../models/language_intelligence_models.dart';
import '../../../models/inline_ai_models.dart';
import '../../../models/ai_models.dart';
import '../../../core/services/diff_engine.dart';

class InlineAIController extends ChangeNotifier {
  final StudioState state;
  InlineAISession? activeSession;
  StreamSubscription<AIStreamEvent>? _streamSubscription;

  InlineAIController({required this.state});

  void triggerInlineAI() {
    final activeTab = state.editor.activeTab;
    if (activeTab == null) return;

    final doc = activeTab.document;
    var range = doc.selection;

    // Fall back to current cursor line if no active selection
    if (range == null || range.isEmpty) {
      final lineNum = doc.cursorLine;
      final lineContent = doc.lines[lineNum - 1];
      range = SelectionRange(
        start: Position(line: lineNum, column: 1),
        end: Position(line: lineNum, column: lineContent.length + 1),
      );
    }

    final reqId = 'inline-req-${DateTime.now().millisecondsSinceEpoch}';
    final request = InlineAIRequest(
      requestId: reqId,
      selection: range,
      prompt: '',
      action: InlineAction.edit,
    );

    activeSession = InlineAISession(
      id: 'inline-sess-${DateTime.now().millisecondsSinceEpoch}',
      documentId: doc.path,
      selectionRange: range,
      request: request,
      state: InlineAIState.prompting,
    );

    notifyListeners();
  }

  Future<void> submitPrompt(String promptText, InlineAction action) async {
    final session = activeSession;
    if (session == null) return;

    activeSession = session.copyWith(
      state: InlineAIState.buildingContext,
      error: null,
    );
    notifyListeners();

    final activeTab = state.editor.activeTab;
    if (activeTab == null) {
      activeSession = session.copyWith(
        state: InlineAIState.failed,
        error: 'No active editor tab found.',
      );
      notifyListeners();
      return;
    }

    final doc = activeTab.document;
    final startOffset = doc.positionToOffset(session.selectionRange.start);
    final endOffset = doc.positionToOffset(session.selectionRange.end);
    final originalText = doc.content.substring(startOffset, endOffset);

    // Gathers Selection context fragment
    final contextFragments = <Map<String, dynamic>>[
      {
        'id': 'selection',
        'source': doc.path,
        'content': originalText,
        'priority': 0,
      },
    ];

    final inlineContext = InlineAIContext(
      contextFragments: contextFragments,
      selection: session.selectionRange,
    );

    activeSession = activeSession!.copyWith(
      context: inlineContext,
      state: InlineAIState.waitingProvider,
    );
    notifyListeners();

    final reqId = 'inline-req-${DateTime.now().millisecondsSinceEpoch}';
    final request = InlineAIRequest(
      requestId: reqId,
      selection: session.selectionRange,
      prompt: promptText,
      action: action,
    );

    activeSession = activeSession!.copyWith(request: request);

    final conversationSession = ConversationSession(
      id: 'inline-sess-${DateTime.now().millisecondsSinceEpoch}',
      title: 'Inline AI Edit',
      workspace: state.activeProject,
      providerId: state.activeTab == 'Workspace'
          ? 'mock-ai'
          : (state.editor.activeTab?.document.language ?? 'mock-ai'),
      modelId: 'inline-model',
      messages: [
        ChatMessage(
          role: ChatRole.system,
          content:
              'You are an inline code editing assistant. The user wants to apply changes to the selection. Return ONLY the replacement code, with no explanation, markdown code fences, or surrounding text.',
          timestamp: DateTime.now(),
        ),
        ChatMessage(
          role: ChatRole.user,
          content:
              'Here is the code to edit:\n```\n$originalText\n```\n\nPrompt: $promptText',
          timestamp: DateTime.now(),
        ),
      ],
      estimatedTokens: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final stream = state.aiService.chatStream(
      session: conversationSession,
      requestId: reqId,
    );

    String accumulatedText = '';
    activeSession = activeSession!.copyWith(state: InlineAIState.streaming);
    notifyListeners();

    await _streamSubscription?.cancel();
    _streamSubscription = stream.listen(
      (event) {
        if (event is TokenChunkEvent) {
          accumulatedText += event.chunk;
          activeSession = activeSession!.copyWith(
            result: InlineAIResult(
              workspaceEdit: WorkspaceEdit(
                changes: {
                  doc.path: [
                    TextEdit(
                      range: session.selectionRange,
                      newText: accumulatedText,
                    ),
                  ],
                },
              ),
              previewText: accumulatedText,
              diff: DiffEngine.computeDiff(
                originalText.split('\n'),
                accumulatedText.split('\n'),
              ),
            ),
          );
          notifyListeners();
        } else if (event is CompletedEvent) {
          accumulatedText = event.fullText;
        } else if (event is ErrorEvent) {
          activeSession = activeSession!.copyWith(
            state: InlineAIState.failed,
            error: '${event.code}: ${event.message}',
          );
          notifyListeners();
        }
      },
      onError: (err) {
        activeSession = activeSession!.copyWith(
          state: InlineAIState.failed,
          error: err.toString(),
        );
        notifyListeners();
      },
      onDone: () {
        if (activeSession!.state == InlineAIState.streaming) {
          activeSession = activeSession!.copyWith(
            state: InlineAIState.computingDiff,
          );
          notifyListeners();

          var cleanText = accumulatedText;
          final trimmed = cleanText.trim();
          if (trimmed.startsWith('```') && trimmed.endsWith('```')) {
            final firstNewline = cleanText.indexOf('\n');
            final lastNewline = cleanText.lastIndexOf('\n');
            if (firstNewline != -1 &&
                lastNewline != -1 &&
                lastNewline > firstNewline) {
              cleanText = cleanText.substring(firstNewline + 1, lastNewline);
            }
          }

          final diff = DiffEngine.computeDiff(
            originalText.split('\n'),
            cleanText.split('\n'),
          );
          final edit = WorkspaceEdit(
            changes: {
              doc.path: [
                TextEdit(range: session.selectionRange, newText: cleanText),
              ],
            },
          );

          activeSession = activeSession!.copyWith(
            state: InlineAIState.reviewing,
            result: InlineAIResult(
              workspaceEdit: edit,
              previewText: cleanText,
              diff: diff,
              finishReason: FinishReason.stop,
            ),
          );
          notifyListeners();
        }
      },
    );
  }

  Future<void> accept() async {
    final session = activeSession;
    if (session == null || session.result == null) return;

    activeSession = session.copyWith(state: InlineAIState.applying);
    notifyListeners();

    final executor = WorkspaceEditExecutor(state: state);
    final res = await executor.execute(session.result!.workspaceEdit);

    if (res.success) {
      activeSession = activeSession!.copyWith(state: InlineAIState.applied);
      notifyListeners();

      final activeTab = state.editor.activeTab;
      if (activeTab != null) {
        state.refreshDiagnosticsForFile(activeTab.document.path);
        state.refreshUI();
      }

      closeSession();
    } else {
      activeSession = activeSession!.copyWith(
        state: InlineAIState.failed,
        error: res.error?.message ?? 'Failed to apply edits.',
      );
      notifyListeners();
    }
  }

  void reject() {
    activeSession = activeSession?.copyWith(state: InlineAIState.rejected);
    notifyListeners();
    closeSession();
  }

  void cancel() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    activeSession = activeSession?.copyWith(state: InlineAIState.cancelled);
    notifyListeners();
    closeSession();
  }

  void retry() {
    final session = activeSession;
    if (session == null) return;

    // Retry invokes submitPrompt reusing the prompt and selection
    submitPrompt(session.request.prompt, session.request.action);
  }

  void closeSession() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    activeSession = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }
}
