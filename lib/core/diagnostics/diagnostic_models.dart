class Position {
  final int line;
  final int column;

  const Position({required this.line, required this.column});

  Map<String, dynamic> toJson() => {
        'line': line,
        'column': column,
      };

  factory Position.fromJson(Map<String, dynamic> json) => Position(
        line: json['line'] as int,
        column: json['column'] as int,
      );
}

class Range {
  final Position start;
  final Position end;

  const Range({required this.start, required this.end});

  Map<String, dynamic> toJson() => {
        'start': start.toJson(),
        'end': end.toJson(),
      };

  factory Range.fromJson(Map<String, dynamic> json) => Range(
        start: Position.fromJson(json['start'] as Map<String, dynamic>),
        end: Position.fromJson(json['end'] as Map<String, dynamic>),
      );
}

class DocumentSnapshot {
  final String path;
  final String content;
  final int revision;
  List<String>? _cachedLines;

  DocumentSnapshot({
    required this.path,
    required this.content,
    required this.revision,
  });

  List<String> get lines => _cachedLines ??= content.split('\n');
}

enum DiagnosticSeverity {
  error,
  warning,
  information,
  hint,
}

enum DiagnosticTag {
  unnecessary,
  deprecated,
}

class DiagnosticRelatedInformation {
  final String path;
  final Range range;
  final String message;

  const DiagnosticRelatedInformation({
    required this.path,
    required this.range,
    required this.message,
  });

  Map<String, dynamic> toJson() => {
        'path': path,
        'range': range.toJson(),
        'message': message,
      };

  factory DiagnosticRelatedInformation.fromJson(Map<String, dynamic> json) =>
      DiagnosticRelatedInformation(
        path: json['path'] as String,
        range: Range.fromJson(json['range'] as Map<String, dynamic>),
        message: json['message'] as String,
      );
}

class Diagnostic {
  final String id;
  final Range range;
  final DiagnosticSeverity severity;
  final String code;
  final String source;
  final String message;
  final List<DiagnosticTag> tags;
  final List<DiagnosticRelatedInformation> relatedInformation;
  final bool hasCodeActions;

  const Diagnostic({
    required this.id,
    required this.range,
    required this.severity,
    required this.code,
    required this.source,
    required this.message,
    this.tags = const [],
    this.relatedInformation = const [],
    this.hasCodeActions = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'range': range.toJson(),
        'severity': severity.name,
        'code': code,
        'source': source,
        'message': message,
        'tags': tags.map((t) => t.name).toList(),
        'relatedInformation':
            relatedInformation.map((r) => r.toJson()).toList(),
        'hasCodeActions': hasCodeActions,
      };

  factory Diagnostic.fromJson(Map<String, dynamic> json) {
    final severityStr = json['severity'] as String;
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
    final related = relatedList
        .map((r) =>
            DiagnosticRelatedInformation.fromJson(r as Map<String, dynamic>))
        .toList();

    return Diagnostic(
      id: json['id'] as String,
      range: Range.fromJson(json['range'] as Map<String, dynamic>),
      severity: severity,
      code: json['code'] as String,
      source: json['source'] as String,
      message: json['message'] as String,
      tags: tags,
      relatedInformation: related,
      hasCodeActions: json['hasCodeActions'] as bool? ?? false,
    );
  }
}

class TextEdit {
  final Range range;
  final String newText;

  const TextEdit({required this.range, required this.newText});

  Map<String, dynamic> toJson() => {
        'range': range.toJson(),
        'newText': newText,
      };

  factory TextEdit.fromJson(Map<String, dynamic> json) => TextEdit(
        range: Range.fromJson(json['range'] as Map<String, dynamic>),
        newText: json['newText'] as String? ?? '',
      );
}

class WorkspaceEdit {
  final Map<String, List<TextEdit>> changes;

  const WorkspaceEdit({required this.changes});

  Map<String, dynamic> toJson() => {
        'changes': changes.map((path, edits) =>
            MapEntry(path, edits.map((e) => e.toJson()).toList())),
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
        'additionalTextEdits':
            additionalTextEdits?.map((e) => e.toJson()).toList(),
        'sortText': sortText,
        'filterText': filterText,
        'deprecated': deprecated,
        'preselect': preselect,
        'score': score,
      };
}

class ParameterInformation {
  final String label;
  final String? documentation;

  const ParameterInformation({required this.label, this.documentation});

  ParameterInformation copyWith({
    String? label,
    String? documentation,
  }) {
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
                (p) => ParameterInformation.fromJson(p as Map<String, dynamic>))
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
            .map(
                (s) => SignatureInformation.fromJson(s as Map<String, dynamic>))
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
