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

  DocumentSnapshot({
    required this.path,
    required this.content,
    required this.revision,
  });

  List<String> get lines => content.split('\n');
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
