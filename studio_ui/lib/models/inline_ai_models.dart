import 'editor_document.dart';
import 'language_intelligence_models.dart';
import 'ai_models.dart';

enum InlineAIState {
  idle,
  prompting,
  buildingContext,
  waitingProvider,
  streaming,
  computingDiff,
  reviewing,
  applying,
  applied,
  rejected,
  cancelled,
  failed,
}

enum InlineAction {
  edit,
  explain,
  refactor,
  fix,
  optimize,
  document,
  test,
}

enum DiffType {
  unchanged,
  inserted,
  deleted,
  modified,
}

class DiffBlock {
  final DiffType type;
  final int oldLine;
  final int newLine;
  final String text;

  const DiffBlock({
    required this.type,
    required this.oldLine,
    required this.newLine,
    required this.text,
  });
}

class InlineAIRequest {
  final String requestId;
  final SelectionRange selection;
  final String prompt;
  final InlineAction action;

  const InlineAIRequest({
    required this.requestId,
    required this.selection,
    required this.prompt,
    required this.action,
  });
}

class InlineAIContext {
  final List<Map<String, dynamic>> contextFragments;
  final SelectionRange selection;

  const InlineAIContext({
    required this.contextFragments,
    required this.selection,
  });
}

class InlineAIResult {
  final WorkspaceEdit workspaceEdit;
  final String previewText;
  final List<DiffBlock> diff;
  final FinishReason? finishReason;

  const InlineAIResult({
    required this.workspaceEdit,
    required this.previewText,
    required this.diff,
    this.finishReason,
  });
}

class InlineAISession {
  final String id;
  final String documentId;
  final SelectionRange selectionRange;
  final InlineAIRequest request;
  final InlineAIContext? context;
  final InlineAIResult? result;
  final InlineAIState state;
  final String? error;

  const InlineAISession({
    required this.id,
    required this.documentId,
    required this.selectionRange,
    required this.request,
    this.context,
    this.result,
    this.state = InlineAIState.prompting,
    this.error,
  });

  InlineAISession copyWith({
    InlineAIRequest? request,
    InlineAIResult? result,
    InlineAIState? state,
    InlineAIContext? context,
    String? error,
  }) {
    return InlineAISession(
      id: id,
      documentId: documentId,
      selectionRange: selectionRange,
      request: request ?? this.request,
      context: context ?? this.context,
      result: result ?? this.result,
      state: state ?? this.state,
      error: error ?? this.error,
    );
  }
}
