import '../core/services/workbench_providers.dart';
import 'editor_document.dart';

class LanguageContext {
  final EditorDocument document;
  final Position position;
  final SelectionRange? selection;
  final String workspace;
  final int workspaceRevision;
  final CancellationToken token;

  const LanguageContext({
    required this.document,
    required this.position,
    this.selection,
    required this.workspace,
    required this.workspaceRevision,
    required this.token,
  });
}

class LanguageRequest {
  final String id;
  final LanguageContext context;
  final Duration timeout;

  const LanguageRequest({
    required this.id,
    required this.context,
    required this.timeout,
  });
}

class ProviderCacheKey {
  final String providerId;
  final String documentId;
  final int revision;
  final String capability;

  const ProviderCacheKey({
    required this.providerId,
    required this.documentId,
    required this.revision,
    required this.capability,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProviderCacheKey &&
          runtimeType == other.runtimeType &&
          providerId == other.providerId &&
          documentId == other.documentId &&
          revision == other.revision &&
          capability == other.capability;

  @override
  int get hashCode =>
      providerId.hashCode ^
      documentId.hashCode ^
      revision.hashCode ^
      capability.hashCode;
}

class ProviderExecutionContext {
  final LanguageRequest request;
  final Stopwatch stopwatch;
  final ProviderMetrics metrics;
  final ProviderCapabilities capabilities;

  const ProviderExecutionContext({
    required this.request,
    required this.stopwatch,
    required this.metrics,
    required this.capabilities,
  });
}

enum ProviderState { ready, initializing, unavailable, failed }

class ProviderMetrics {
  int requestCount = 0;
  int successCount = 0;
  int failedCount = 0;
  Duration totalLatency = Duration.zero;

  Duration get averageLatency =>
      requestCount == 0 ? Duration.zero : totalLatency ~/ requestCount;
}

abstract class LanguageProvider {
  String get id;
  String get language;
  int get version;
  int get priority;

  ProviderState get state;
  ProviderMetrics get metrics;

  Future<void> initialize();
  Future<void> start();
  Future<void> stop();
  Future<void> dispose();
}

class ProviderCapabilities {
  final bool hover;
  final bool completion;
  final bool diagnostics;
  final bool semanticTokens;
  final bool rename;

  const ProviderCapabilities({
    this.hover = false,
    this.completion = false,
    this.diagnostics = false,
    this.semanticTokens = false,
    this.rename = false,
  });
}

class SemanticTokensResult {
  final bool isDelta;
  final List<int> data;
  final String? resultId;

  const SemanticTokensResult({
    this.isDelta = false,
    required this.data,
    this.resultId,
  });
}

class Hover {
  final String contents;
  final SelectionRange? range;

  const Hover({required this.contents, this.range});
}

class DiagnosticId {
  final String source;
  final String code;
  final String path;
  final int revision;

  const DiagnosticId({
    required this.source,
    required this.code,
    required this.path,
    required this.revision,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiagnosticId &&
          runtimeType == other.runtimeType &&
          source == other.source &&
          code == other.code &&
          path == other.path &&
          revision == other.revision;

  @override
  int get hashCode =>
      source.hashCode ^ code.hashCode ^ path.hashCode ^ revision.hashCode;
}

enum DiagnosticSeverity { error, warning, information, hint }

enum DiagnosticTag { unnecessary, deprecated }

class DiagnosticRelatedInformation {
  final String path;
  final SelectionRange range;
  final String message;

  const DiagnosticRelatedInformation({
    required this.path,
    required this.range,
    required this.message,
  });
}

class Diagnostic {
  final String id;
  final String message;
  final SelectionRange range;
  final DiagnosticSeverity severity;
  final String code;
  final String source;
  final List<DiagnosticTag> tags;
  final List<DiagnosticRelatedInformation> relatedInformation;
  final bool hasCodeActions;

  const Diagnostic({
    required this.id,
    required this.message,
    required this.range,
    this.severity = DiagnosticSeverity.error,
    required this.code,
    required this.source,
    this.tags = const [],
    this.relatedInformation = const [],
    this.hasCodeActions = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'message': message,
    'range': {'start': range.start.toJson(), 'end': range.end.toJson()},
    'severity': severity.name,
    'code': code,
    'source': source,
    'tags': tags.map((t) => t.name).toList(),
    'relatedInformation': relatedInformation
        .map(
          (r) => {
            'path': r.path,
            'range': {
              'start': r.range.start.toJson(),
              'end': r.range.end.toJson(),
            },
            'message': r.message,
          },
        )
        .toList(),
    'hasCodeActions': hasCodeActions,
  };

  factory Diagnostic.fromJson(Map<String, dynamic> json) {
    final severityStr = json['severity'] as String? ?? 'error';
    final severity = DiagnosticSeverity.values.firstWhere(
      (e) => e.name == severityStr,
      orElse: () => DiagnosticSeverity.error,
    );

    final tagsList = (json['tags'] as List? ?? []);
    final tags = tagsList.map((tagStr) {
      return DiagnosticTag.values.firstWhere(
        (e) => e.name == tagStr,
        orElse: () => DiagnosticTag.deprecated,
      );
    }).toList();

    final relatedList = (json['relatedInformation'] as List? ?? []);
    final related = relatedList.map((r) {
      final map = r as Map<String, dynamic>;
      final start = Position.fromJson(
        map['range']['start'] as Map<String, dynamic>,
      );
      final end = Position.fromJson(
        map['range']['end'] as Map<String, dynamic>,
      );
      return DiagnosticRelatedInformation(
        path: map['path'] as String? ?? '',
        range: SelectionRange(start: start, end: end),
        message: map['message'] as String? ?? '',
      );
    }).toList();

    final startMap = json['range']['start'] as Map<String, dynamic>;
    final endMap = json['range']['end'] as Map<String, dynamic>;

    return Diagnostic(
      id: json['id'] as String? ?? '',
      message: json['message'] as String? ?? '',
      range: SelectionRange(
        start: Position(
          line: startMap['line'] as int? ?? 1,
          column: startMap['column'] as int? ?? 1,
        ),
        end: Position(
          line: endMap['line'] as int? ?? 1,
          column: endMap['column'] as int? ?? 1,
        ),
      ),
      severity: severity,
      code: json['code'] as String? ?? '',
      source: json['source'] as String? ?? '',
      tags: tags,
      relatedInformation: related,
      hasCodeActions: json['hasCodeActions'] as bool? ?? false,
    );
  }
}

enum CompletionTriggerKind { automatic, manual, triggerCharacter, incomplete }

class CompletionTrigger {
  final CompletionTriggerKind kind;
  final String? character;

  const CompletionTrigger({required this.kind, this.character});
}

enum CompletionItemKind {
  text,
  method,
  function,
  constructor,
  field,
  variable,
  classType,
  interface,
  module,
  property,
  keyword,
  snippet,
  file,
  folder,
  enumType,
  constant,
}

class CompletionItem {
  final String label;
  final CompletionItemKind kind;
  final String? detail;
  final String? documentation;
  final String insertText;
  final int insertTextFormat; // 1 = PlainText, 2 = Snippet
  final TextEdit? textEdit;
  final List<TextEdit>? additionalTextEdits;
  final String? sortText;
  final String? filterText;
  final bool deprecated;
  final bool preselect;
  final double score;

  const CompletionItem({
    required this.label,
    required this.kind,
    this.detail,
    this.documentation,
    required this.insertText,
    this.insertTextFormat = 1,
    this.textEdit,
    this.additionalTextEdits,
    this.sortText,
    this.filterText,
    this.deprecated = false,
    this.preselect = false,
    this.score = 0.0,
  });

  Map<String, dynamic> toJson() => {
    'label': label,
    'kind': kind.name,
    'detail': detail,
    'documentation': documentation,
    'insertText': insertText,
    'insertTextFormat': insertTextFormat,
    'textEdit': textEdit?.toJson(),
    'additionalTextEdits': additionalTextEdits?.map((e) => e.toJson()).toList(),
    'sortText': sortText,
    'filterText': filterText,
    'deprecated': deprecated,
    'preselect': preselect,
    'score': score,
  };

  factory CompletionItem.fromJson(Map<String, dynamic> json) {
    final kindStr = json['kind'] as String;
    final kind = CompletionItemKind.values.firstWhere(
      (e) => e.name == kindStr,
      orElse: () => CompletionItemKind.text,
    );

    final addEdits = (json['additionalTextEdits'] as List? ?? [])
        .map((e) => TextEdit.fromJson(e as Map<String, dynamic>))
        .toList();

    return CompletionItem(
      label: json['label'] as String,
      kind: kind,
      detail: json['detail'] as String?,
      documentation: json['documentation'] as String?,
      insertText: json['insertText'] as String? ?? json['label'] as String,
      insertTextFormat: json['insertTextFormat'] as int? ?? 1,
      textEdit: json['textEdit'] != null
          ? TextEdit.fromJson(json['textEdit'] as Map<String, dynamic>)
          : null,
      additionalTextEdits: addEdits,
      sortText: json['sortText'] as String?,
      filterText: json['filterText'] as String?,
      deprecated: json['deprecated'] as bool? ?? false,
      preselect: json['preselect'] as bool? ?? false,
      score: (json['score'] as num? ?? 0.0).toDouble(),
    );
  }
}

enum SignatureTriggerKind { automatic, manual }

class ParameterInformation {
  final String label;
  final String? documentation;

  const ParameterInformation({required this.label, this.documentation});

  ParameterInformation copyWith({String? label, String? documentation}) {
    return ParameterInformation(
      label: label ?? this.label,
      documentation: documentation ?? this.documentation,
    );
  }

  Map<String, dynamic> toJson() => {
    'label': label,
    'documentation': documentation,
  };

  factory ParameterInformation.fromJson(Map<String, dynamic> json) =>
      ParameterInformation(
        label: json['label'] as String,
        documentation: json['documentation'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParameterInformation &&
          runtimeType == other.runtimeType &&
          label == other.label &&
          documentation == other.documentation;

  @override
  int get hashCode => label.hashCode ^ documentation.hashCode;
}

class SignatureInformation {
  final String label;
  final String? documentation;
  final List<ParameterInformation> parameters;

  const SignatureInformation({
    required this.label,
    this.documentation,
    required this.parameters,
  });

  SignatureInformation copyWith({
    String? label,
    String? documentation,
    List<ParameterInformation>? parameters,
  }) {
    return SignatureInformation(
      label: label ?? this.label,
      documentation: documentation ?? this.documentation,
      parameters: parameters ?? this.parameters,
    );
  }

  Map<String, dynamic> toJson() => {
    'label': label,
    'documentation': documentation,
    'parameters': parameters.map((p) => p.toJson()).toList(),
  };

  factory SignatureInformation.fromJson(Map<String, dynamic> json) =>
      SignatureInformation(
        label: json['label'] as String,
        documentation: json['documentation'] as String?,
        parameters: (json['parameters'] as List? ?? [])
            .map(
              (p) => ParameterInformation.fromJson(p as Map<String, dynamic>),
            )
            .toList(),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SignatureInformation &&
          runtimeType == other.runtimeType &&
          label == other.label &&
          documentation == other.documentation &&
          _listEquals(parameters, other.parameters);

  @override
  int get hashCode =>
      label.hashCode ^ documentation.hashCode ^ _listHashCode(parameters);

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static int _listHashCode<T>(List<T> list) {
    int hash = 0;
    for (final item in list) {
      hash ^= item.hashCode;
    }
    return hash;
  }
}

class SignatureHelp {
  final List<SignatureInformation> signatures;
  final int activeSignature;
  final int activeParameter;

  const SignatureHelp({
    required this.signatures,
    this.activeSignature = 0,
    this.activeParameter = 0,
  });

  SignatureHelp copyWith({
    List<SignatureInformation>? signatures,
    int? activeSignature,
    int? activeParameter,
  }) {
    return SignatureHelp(
      signatures: signatures ?? this.signatures,
      activeSignature: activeSignature ?? this.activeSignature,
      activeParameter: activeParameter ?? this.activeParameter,
    );
  }

  Map<String, dynamic> toJson() => {
    'signatures': signatures.map((s) => s.toJson()).toList(),
    'activeSignature': activeSignature,
    'activeParameter': activeParameter,
  };

  factory SignatureHelp.fromJson(Map<String, dynamic> json) => SignatureHelp(
    signatures: (json['signatures'] as List? ?? [])
        .map((s) => SignatureInformation.fromJson(s as Map<String, dynamic>))
        .toList(),
    activeSignature: json['activeSignature'] as int? ?? 0,
    activeParameter: json['activeParameter'] as int? ?? 0,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SignatureHelp &&
          runtimeType == other.runtimeType &&
          activeSignature == other.activeSignature &&
          activeParameter == other.activeParameter &&
          SignatureInformation._listEquals(signatures, other.signatures);

  @override
  int get hashCode =>
      signatures.hashCode ^ activeSignature.hashCode ^ activeParameter.hashCode;
}

enum CodeActionKind {
  quickFix('quickfix'),
  refactor('refactor'),
  refactorExtract('refactor.extract'),
  refactorInline('refactor.inline'),
  refactorRewrite('refactor.rewrite'),
  source('source'),
  sourceOrganizeImports('source.organizeImports'),
  sourceFixAll('source.fixAll');

  final String value;
  const CodeActionKind(this.value);

  static CodeActionKind fromString(String val) {
    return CodeActionKind.values.firstWhere(
      (e) => e.value == val || e.name == val,
      orElse: () => CodeActionKind.quickFix,
    );
  }
}

class CodeAction {
  final String id;
  final String title;
  final CodeActionKind kind;
  final WorkspaceEdit? edit;
  final bool isPreferred;
  final bool requiresConfirmation;
  final bool isPreviewable;
  final String? disabledReason;
  final String? providerId;
  final String? command;
  final List<Diagnostic>? diagnostics;

  const CodeAction({
    required this.id,
    required this.title,
    required this.kind,
    this.edit,
    this.isPreferred = false,
    this.requiresConfirmation = false,
    this.isPreviewable = false,
    this.disabledReason,
    this.providerId,
    this.command,
    this.diagnostics,
  });

  CodeAction copyWith({
    String? id,
    String? title,
    CodeActionKind? kind,
    WorkspaceEdit? edit,
    bool? isPreferred,
    bool? requiresConfirmation,
    bool? isPreviewable,
    String? disabledReason,
    String? providerId,
    String? command,
    List<Diagnostic>? diagnostics,
  }) {
    return CodeAction(
      id: id ?? this.id,
      title: title ?? this.title,
      kind: kind ?? this.kind,
      edit: edit ?? this.edit,
      isPreferred: isPreferred ?? this.isPreferred,
      requiresConfirmation: requiresConfirmation ?? this.requiresConfirmation,
      isPreviewable: isPreviewable ?? this.isPreviewable,
      disabledReason: disabledReason ?? this.disabledReason,
      providerId: providerId ?? this.providerId,
      command: command ?? this.command,
      diagnostics: diagnostics ?? this.diagnostics,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'kind': kind.value,
    'edit': edit?.toJson(),
    'isPreferred': isPreferred,
    'requiresConfirmation': requiresConfirmation,
    'isPreviewable': isPreviewable,
    'disabledReason': disabledReason,
    'providerId': providerId,
    'command': command,
    'diagnostics': diagnostics?.map((d) => d.toJson()).toList(),
  };

  factory CodeAction.fromJson(Map<String, dynamic> json) {
    final kindStr = json['kind'] as String? ?? 'quickfix';
    final kind = CodeActionKind.fromString(kindStr);

    final editVal = json['edit'];
    final edit = editVal != null
        ? WorkspaceEdit.fromJson(editVal as Map<String, dynamic>)
        : null;

    final diagList = json['diagnostics'] as List?;
    final diagnostics = diagList != null
        ? diagList
              .map((d) => Diagnostic.fromJson(d as Map<String, dynamic>))
              .toList()
        : null;

    return CodeAction(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      kind: kind,
      edit: edit,
      isPreferred: json['isPreferred'] as bool? ?? false,
      requiresConfirmation: json['requiresConfirmation'] as bool? ?? false,
      isPreviewable: json['isPreviewable'] as bool? ?? false,
      disabledReason: json['disabledReason'] as String?,
      providerId: json['providerId'] as String?,
      command: json['command'] as String?,
      diagnostics: diagnostics,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CodeAction &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          kind == other.kind &&
          edit == other.edit &&
          isPreferred == other.isPreferred &&
          requiresConfirmation == other.requiresConfirmation &&
          isPreviewable == other.isPreviewable &&
          disabledReason == other.disabledReason &&
          providerId == other.providerId &&
          command == other.command &&
          _listEquals(diagnostics, other.diagnostics);

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      kind.hashCode ^
      edit.hashCode ^
      isPreferred.hashCode ^
      requiresConfirmation.hashCode ^
      isPreviewable.hashCode ^
      disabledReason.hashCode ^
      providerId.hashCode ^
      command.hashCode ^
      _listHashCode(diagnostics);

  static bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static int _listHashCode<T>(List<T>? list) {
    if (list == null) return 0;
    int hash = 0;
    for (final item in list) {
      hash ^= item.hashCode;
    }
    return hash;
  }
}

class DocumentSymbol {
  final String name;
  final String kind;
  final SelectionRange range;
  final SelectionRange selectionRange;
  final List<DocumentSymbol> children;

  const DocumentSymbol({
    required this.name,
    required this.kind,
    required this.range,
    required this.selectionRange,
    required this.children,
  });
}

class CallHierarchyItem {
  final String name;
  final String kind;
  final String uri;
  final SelectionRange range;
  final SelectionRange selectionRange;

  const CallHierarchyItem({
    required this.name,
    required this.kind,
    required this.uri,
    required this.range,
    required this.selectionRange,
  });
}

class TypeHierarchyItem {
  final String name;
  final String kind;
  final String uri;
  final SelectionRange range;
  final SelectionRange selectionRange;

  const TypeHierarchyItem({
    required this.name,
    required this.kind,
    required this.uri,
    required this.range,
    required this.selectionRange,
  });
}

class CodeLens {
  final SelectionRange range;
  final String? command;

  const CodeLens({required this.range, this.command});
}

class InlayHint {
  final Position position;
  final String label;
  final String? tooltip;

  const InlayHint({required this.position, required this.label, this.tooltip});
}

class TextEdit {
  final SelectionRange range;
  final String newText;

  const TextEdit({required this.range, required this.newText});

  Map<String, dynamic> toJson() => {
    'range': range.toJson(),
    'newText': newText,
  };

  factory TextEdit.fromJson(Map<String, dynamic> json) => TextEdit(
    range: SelectionRange.fromJson(json['range'] as Map<String, dynamic>),
    newText: json['newText'] as String? ?? '',
  );
}

class WorkspaceEdit {
  final Map<String, List<TextEdit>> changes;

  const WorkspaceEdit({required this.changes});

  Map<String, dynamic> toJson() => {
    'changes': changes.map(
      (path, edits) => MapEntry(path, edits.map((e) => e.toJson()).toList()),
    ),
  };

  factory WorkspaceEdit.fromJson(Map<String, dynamic> json) {
    final changesMap = json['changes'] as Map<String, dynamic>? ?? {};
    final parsedChanges = <String, List<TextEdit>>{};
    changesMap.forEach((path, editsList) {
      if (editsList is List) {
        parsedChanges[path] = editsList
            .map((e) => TextEdit.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    });
    return WorkspaceEdit(changes: parsedChanges);
  }
}
