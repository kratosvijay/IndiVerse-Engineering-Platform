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

enum DiagnosticSeverity { error, warning, information, hint }

class Diagnostic {
  final String message;
  final SelectionRange range;
  final DiagnosticSeverity severity;
  final String? code;
  final String? source;

  const Diagnostic({
    required this.message,
    required this.range,
    this.severity = DiagnosticSeverity.error,
    this.code,
    this.source,
  });
}

enum CompletionItemKind {
  text,
  method,
  function,
  constructor,
  field,
  variable,
  class_,
  interface,
  module,
  property,
  unit,
  value,
  enum_,
  keyword,
  snippet,
  color,
  file,
  reference,
  folder,
  enumMember,
  constant,
  struct,
  event,
  operator,
  typeParameter,
}

class CompletionItem {
  final String label;
  final CompletionItemKind kind;
  final String? detail;
  final String? documentation;
  final String? insertText;
  final SelectionRange? range;

  const CompletionItem({
    required this.label,
    required this.kind,
    this.detail,
    this.documentation,
    this.insertText,
    this.range,
  });
}

class ParameterInformation {
  final String label;
  final String? documentation;

  const ParameterInformation({required this.label, this.documentation});
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
}

class TextEdit {
  final SelectionRange range;
  final String newText;

  const TextEdit({required this.range, required this.newText});
}

class WorkspaceEdit {
  final Map<String, List<TextEdit>> changes;

  const WorkspaceEdit({required this.changes});
}

class CodeAction {
  final String title;
  final String kind;
  final WorkspaceEdit? edit;
  final bool isPreferred;

  const CodeAction({
    required this.title,
    required this.kind,
    this.edit,
    this.isPreferred = false,
  });
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
