import '../../models/language_intelligence_models.dart';
import 'language_intelligence_providers.dart';
import 'semantic_token_cache.dart';

class LanguageProviderRegistry {
  final SemanticTokenCache semanticCache = SemanticTokenCache();
  final Map<String, List<HoverProvider>> _hoverProviders = {};
  final Map<String, List<SemanticTokensProvider>> _semanticTokensProviders = {};
  final Map<String, List<DiagnosticsProvider>> _diagnosticsProviders = {};
  final Map<String, List<CompletionItemProvider>> _completionProviders = {};
  final Map<String, List<SignatureHelpProvider>> _signatureHelpProviders = {};
  final Map<String, List<CodeActionProvider>> _codeActionProviders = {};

  Future<void> registerHoverProvider(
    String language,
    HoverProvider provider,
  ) async {
    await provider.initialize();
    await provider.start();
    _hoverProviders.putIfAbsent(language, () => []).add(provider);
    _hoverProviders[language]!.sort((a, b) => b.priority.compareTo(a.priority));
  }

  Future<void> registerSemanticTokensProvider(
    String language,
    SemanticTokensProvider provider,
  ) async {
    await provider.initialize();
    await provider.start();
    _semanticTokensProviders.putIfAbsent(language, () => []).add(provider);
    _semanticTokensProviders[language]!.sort(
      (a, b) => b.priority.compareTo(a.priority),
    );
  }

  Future<void> registerDiagnosticsProvider(
    String language,
    DiagnosticsProvider provider,
  ) async {
    await provider.initialize();
    await provider.start();
    _diagnosticsProviders.putIfAbsent(language, () => []).add(provider);
    _diagnosticsProviders[language]!.sort(
      (a, b) => b.priority.compareTo(a.priority),
    );
  }

  Future<void> registerCompletionProvider(
    String language,
    CompletionItemProvider provider,
  ) async {
    await provider.initialize();
    await provider.start();
    _completionProviders.putIfAbsent(language, () => []).add(provider);
    _completionProviders[language]!.sort(
      (a, b) => b.priority.compareTo(a.priority),
    );
  }

  Future<void> registerSignatureHelpProvider(
    String language,
    SignatureHelpProvider provider,
  ) async {
    await provider.initialize();
    await provider.start();
    _signatureHelpProviders.putIfAbsent(language, () => []).add(provider);
    _signatureHelpProviders[language]!.sort(
      (a, b) => b.priority.compareTo(a.priority),
    );
  }

  Future<void> registerCodeActionProvider(
    String language,
    CodeActionProvider provider,
  ) async {
    await provider.initialize();
    await provider.start();
    _codeActionProviders.putIfAbsent(language, () => []).add(provider);
    _codeActionProviders[language]!.sort(
      (a, b) => b.priority.compareTo(a.priority),
    );
  }

  HoverProvider? getHoverProvider(String language) {
    final list = _hoverProviders[language];
    return (list != null && list.isNotEmpty) ? list.first : null;
  }

  SemanticTokensProvider? getSemanticTokensProvider(String language) {
    final list = _semanticTokensProviders[language];
    return (list != null && list.isNotEmpty) ? list.first : null;
  }

  DiagnosticsProvider? getDiagnosticsProvider(String language) {
    final list = _diagnosticsProviders[language];
    return (list != null && list.isNotEmpty) ? list.first : null;
  }

  CompletionItemProvider? getCompletionProvider(String language) {
    final list = _completionProviders[language];
    return (list != null && list.isNotEmpty) ? list.first : null;
  }

  SignatureHelpProvider? getSignatureHelpProvider(String language) {
    final list = _signatureHelpProviders[language];
    return (list != null && list.isNotEmpty) ? list.first : null;
  }

  CodeActionProvider? getCodeActionProvider(String language) {
    final list = _codeActionProviders[language];
    return (list != null && list.isNotEmpty) ? list.first : null;
  }

  ProviderCapabilities getCapabilities(String language) {
    return ProviderCapabilities(
      hover: _hoverProviders[language]?.isNotEmpty ?? false,
      completion: _completionProviders[language]?.isNotEmpty ?? false,
      diagnostics: _diagnosticsProviders[language]?.isNotEmpty ?? false,
      semanticTokens: _semanticTokensProviders[language]?.isNotEmpty ?? false,
      rename: false, // Future capability
    );
  }
}
