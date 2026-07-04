import '../../models/language_intelligence_models.dart';
import 'workbench_providers.dart';

abstract class HoverProvider implements LanguageProvider {
  Future<OperationResult<Hover>> provideHover(
    ProviderExecutionContext context,
  );
}

abstract class SemanticTokensProvider implements LanguageProvider {
  Future<OperationResult<SemanticTokensResult>> provideSemanticTokens(
    ProviderExecutionContext context,
  );
}

abstract class DiagnosticsProvider implements LanguageProvider {
  Future<OperationResult<List<Diagnostic>>> provideDiagnostics(
    ProviderExecutionContext context,
  );
}

abstract class CompletionItemProvider implements LanguageProvider {
  Future<OperationResult<List<CompletionItem>>> provideCompletions(
    ProviderExecutionContext context,
  );
}

abstract class SignatureHelpProvider implements LanguageProvider {
  Future<OperationResult<SignatureHelp>> provideSignatureHelp(
    ProviderExecutionContext context,
  );
}

abstract class CodeActionProvider implements LanguageProvider {
  Future<OperationResult<List<CodeAction>>> provideCodeActions(
    ProviderExecutionContext context,
  );
}

abstract class RenameProvider implements LanguageProvider {
  Future<OperationResult<WorkspaceEdit>> provideRename(
    ProviderExecutionContext context,
    String newName,
  );
}

abstract class FormattingProvider implements LanguageProvider {
  Future<OperationResult<List<TextEdit>>> provideFormatting(
    ProviderExecutionContext context,
  );
}

abstract class DocumentSymbolsProvider implements LanguageProvider {
  Future<OperationResult<List<DocumentSymbol>>> provideDocumentSymbols(
    ProviderExecutionContext context,
  );
}

abstract class CallHierarchyProvider implements LanguageProvider {
  Future<OperationResult<List<CallHierarchyItem>>> provideCallHierarchy(
    ProviderExecutionContext context,
  );
}

abstract class TypeHierarchyProvider implements LanguageProvider {
  Future<OperationResult<List<TypeHierarchyItem>>> provideTypeHierarchy(
    ProviderExecutionContext context,
  );
}

abstract class CodeLensProvider implements LanguageProvider {
  Future<OperationResult<List<CodeLens>>> provideCodeLenses(
    ProviderExecutionContext context,
  );
}

abstract class InlayHintProvider implements LanguageProvider {
  Future<OperationResult<List<InlayHint>>> provideInlayHints(
    ProviderExecutionContext context,
  );
}
