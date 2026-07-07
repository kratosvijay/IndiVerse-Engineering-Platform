import 'dart:async';
import '../../models/language_intelligence_models.dart';
import 'language_provider_registry.dart';
import 'workbench_providers.dart';
import 'completion_cache.dart';
import 'signature_help_cache.dart';
import 'code_action_cache.dart';

class IntelligenceCacheEntry<T> {
  final T result;
  final int documentRevision;
  final int workspaceRevision;
  final DateTime timestamp;

  const IntelligenceCacheEntry({
    required this.result,
    required this.documentRevision,
    required this.workspaceRevision,
    required this.timestamp,
  });
}

class LanguageIntelligenceService {
  final LanguageProviderRegistry registry;

  final Map<ProviderCacheKey, IntelligenceCacheEntry<Hover>> _hoverCache = {};
  final Map<ProviderCacheKey, IntelligenceCacheEntry<SemanticTokensResult>>
  _semanticTokensCache = {};
  final Map<ProviderCacheKey, IntelligenceCacheEntry<List<Diagnostic>>>
  _diagnosticsCache = {};
  final CompletionCache completionCache = CompletionCache();
  final SignatureHelpCache signatureHelpCache = SignatureHelpCache();
  final CodeActionCache codeActionCache = CodeActionCache();

  // Metric fields for autocomplete
  int completionRequests = 0;
  int completionCacheHits = 0;

  // Metric fields for signature help
  int signatureRequests = 0;
  int signatureCacheHits = 0;
  int signatureTimeouts = 0;
  String activeSignatureProvider = 'none';
  Duration totalSignatureLatency = Duration.zero;

  // Metric fields for code actions
  int codeActionRequests = 0;
  int codeActionCacheHits = 0;
  int codeActionTimeouts = 0;
  int codeActionsApplied = 0;
  int codeActionsFailed = 0;
  Duration totalCodeActionLatency = Duration.zero;
  Duration totalCodeActionApplyTime = Duration.zero;
  String activeCodeActionProvider = '';

  LanguageIntelligenceService(this.registry);

  void invalidateCache(String path) {
    _hoverCache.removeWhere((key, val) => key.documentId == path);
    _semanticTokensCache.removeWhere((key, val) => key.documentId == path);
    _diagnosticsCache.removeWhere((key, val) => key.documentId == path);
    completionCache.invalidatePath(path);
    signatureHelpCache.invalidatePath(path);
    codeActionCache.invalidatePath(path);
  }

  Future<OperationResult<Hover>> getHover(LanguageContext context) async {
    final language = context.document.language;
    final path = context.document.path;

    final provider = registry.getHoverProvider(language);
    if (provider == null) {
      return const OperationResult.fail(
        WorkbenchError(
          code: 'UNSUPPORTED_LANGUAGE',
          message: 'No hover provider registered.',
        ),
      );
    }

    final cacheKey = ProviderCacheKey(
      providerId: provider.id,
      documentId: path,
      revision: context.document.version.localRevision,
      capability: 'hover',
    );

    final cached = _hoverCache[cacheKey];
    if (cached != null &&
        cached.workspaceRevision == context.workspaceRevision) {
      return OperationResult.ok(cached.result);
    }

    final req = LanguageRequest(
      id: 'hover-${DateTime.now().millisecondsSinceEpoch}',
      context: context,
      timeout: const Duration(milliseconds: 500),
    );

    final execCtx = ProviderExecutionContext(
      request: req,
      stopwatch: Stopwatch()..start(),
      metrics: provider.metrics,
      capabilities: registry.getCapabilities(language),
    );

    provider.metrics.requestCount++;

    try {
      final res = await provider.provideHover(execCtx).timeout(req.timeout);
      execCtx.stopwatch.stop();
      if (res.success && res.data != null) {
        provider.metrics.successCount++;
        provider.metrics.totalLatency += execCtx.stopwatch.elapsed;
        _hoverCache[cacheKey] = IntelligenceCacheEntry(
          result: res.data!,
          documentRevision: context.document.version.localRevision,
          workspaceRevision: context.workspaceRevision,
          timestamp: DateTime.now(),
        );
      } else {
        provider.metrics.failedCount++;
      }
      return res;
    } on TimeoutException {
      provider.metrics.failedCount++;
      context.token.cancel();
      return const OperationResult.fail(
        WorkbenchError(code: 'TIMEOUT', message: 'Hover request timed out.'),
      );
    } catch (e) {
      provider.metrics.failedCount++;
      return OperationResult.fail(
        WorkbenchError(code: 'INTERNAL_ERROR', message: e.toString()),
      );
    }
  }

  Future<OperationResult<SemanticTokensResult>> getSemanticTokens(
    LanguageContext context,
  ) async {
    final language = context.document.language;
    final path = context.document.path;

    final provider = registry.getSemanticTokensProvider(language);
    if (provider == null) {
      return const OperationResult.fail(
        WorkbenchError(
          code: 'UNSUPPORTED_LANGUAGE',
          message: 'No semantic tokens provider registered.',
        ),
      );
    }

    final cacheKey = ProviderCacheKey(
      providerId: provider.id,
      documentId: path,
      revision: context.document.version.localRevision,
      capability: 'semanticTokens',
    );

    final cached = _semanticTokensCache[cacheKey];
    if (cached != null &&
        cached.workspaceRevision == context.workspaceRevision) {
      return OperationResult.ok(cached.result);
    }

    final req = LanguageRequest(
      id: 'sem-${DateTime.now().millisecondsSinceEpoch}',
      context: context,
      timeout: const Duration(seconds: 5),
    );

    final execCtx = ProviderExecutionContext(
      request: req,
      stopwatch: Stopwatch()..start(),
      metrics: provider.metrics,
      capabilities: registry.getCapabilities(language),
    );

    provider.metrics.requestCount++;

    try {
      final res = await provider
          .provideSemanticTokens(execCtx)
          .timeout(req.timeout);
      execCtx.stopwatch.stop();
      if (res.success && res.data != null) {
        provider.metrics.successCount++;
        provider.metrics.totalLatency += execCtx.stopwatch.elapsed;
        _semanticTokensCache[cacheKey] = IntelligenceCacheEntry(
          result: res.data!,
          documentRevision: context.document.version.localRevision,
          workspaceRevision: context.workspaceRevision,
          timestamp: DateTime.now(),
        );
      } else {
        provider.metrics.failedCount++;
      }
      return res;
    } on TimeoutException {
      provider.metrics.failedCount++;
      context.token.cancel();
      return const OperationResult.fail(
        WorkbenchError(
          code: 'TIMEOUT',
          message: 'Semantic tokens request timed out.',
        ),
      );
    } catch (e) {
      provider.metrics.failedCount++;
      return OperationResult.fail(
        WorkbenchError(code: 'INTERNAL_ERROR', message: e.toString()),
      );
    }
  }

  Future<OperationResult<List<Diagnostic>>> getDiagnostics(
    LanguageContext context,
  ) async {
    final language = context.document.language;
    final path = context.document.path;

    final provider = registry.getDiagnosticsProvider(language);
    if (provider == null) {
      return const OperationResult.fail(
        WorkbenchError(
          code: 'UNSUPPORTED_LANGUAGE',
          message: 'No diagnostics provider registered.',
        ),
      );
    }

    final cacheKey = ProviderCacheKey(
      providerId: provider.id,
      documentId: path,
      revision: context.document.version.localRevision,
      capability: 'diagnostics',
    );

    final cached = _diagnosticsCache[cacheKey];
    if (cached != null &&
        cached.workspaceRevision == context.workspaceRevision) {
      return OperationResult.ok(cached.result);
    }

    final req = LanguageRequest(
      id: 'diag-${DateTime.now().millisecondsSinceEpoch}',
      context: context,
      timeout: const Duration(seconds: 5),
    );

    final execCtx = ProviderExecutionContext(
      request: req,
      stopwatch: Stopwatch()..start(),
      metrics: provider.metrics,
      capabilities: registry.getCapabilities(language),
    );

    provider.metrics.requestCount++;

    try {
      final res = await provider
          .provideDiagnostics(execCtx)
          .timeout(req.timeout);
      execCtx.stopwatch.stop();
      if (res.success && res.data != null) {
        provider.metrics.successCount++;
        provider.metrics.totalLatency += execCtx.stopwatch.elapsed;
        _diagnosticsCache[cacheKey] = IntelligenceCacheEntry(
          result: res.data!,
          documentRevision: context.document.version.localRevision,
          workspaceRevision: context.workspaceRevision,
          timestamp: DateTime.now(),
        );
      } else {
        provider.metrics.failedCount++;
      }
      return res;
    } on TimeoutException {
      provider.metrics.failedCount++;
      context.token.cancel();
      return const OperationResult.fail(
        WorkbenchError(
          code: 'TIMEOUT',
          message: 'Diagnostics request timed out.',
        ),
      );
    } catch (e) {
      provider.metrics.failedCount++;
      return OperationResult.fail(
        WorkbenchError(code: 'INTERNAL_ERROR', message: e.toString()),
      );
    }
  }

  Future<OperationResult<List<CompletionItem>>> getCompletions(
    LanguageContext context,
    CompletionTrigger trigger,
  ) async {
    completionRequests++;
    final language = context.document.language;
    final path = context.document.path;
    final revision = context.document.version.localRevision;

    String prefix = '';
    try {
      final pos = context.position;
      final lineContent = context.document.lines[pos.line - 1];
      final col = pos.column - 1;
      if (col > 0 && col <= lineContent.length) {
        int start = col - 1;
        while (start >= 0) {
          final c = lineContent[start];
          if (RegExp(r'[a-zA-Z0-9_]').hasMatch(c)) {
            start--;
          } else {
            break;
          }
        }
        prefix = lineContent.substring(start + 1, col);
      }
    } catch (_) {}

    final providers = registry.getCompletionProviders(language);
    if (providers.isEmpty) {
      return const OperationResult.fail(
        WorkbenchError(
          code: 'UNSUPPORTED_LANGUAGE',
          message: 'No completion providers registered.',
        ),
      );
    }

    final versionsString = providers
        .map((p) => '${p.id}@${p.version}')
        .join(',');
    final cached = completionCache.get(
      language,
      versionsString,
      path,
      revision,
      prefix,
    );
    if (cached != null) {
      completionCacheHits++;
      return OperationResult.ok(cached);
    }

    final results = <CompletionItem>[];
    final req = LanguageRequest(
      id: 'completion-${DateTime.now().millisecondsSinceEpoch}',
      context: context,
      timeout: const Duration(seconds: 2),
    );

    final futures = providers.map((provider) async {
      final execCtx = ProviderExecutionContext(
        request: req,
        stopwatch: Stopwatch()..start(),
        metrics: provider.metrics,
        capabilities: registry.getCapabilities(language),
      );
      provider.metrics.requestCount++;
      try {
        final res = await provider
            .provideCompletions(execCtx)
            .timeout(req.timeout);
        execCtx.stopwatch.stop();
        if (res.success && res.data != null) {
          provider.metrics.successCount++;
          provider.metrics.totalLatency += execCtx.stopwatch.elapsed;
          return res.data!;
        } else {
          provider.metrics.failedCount++;
        }
      } catch (_) {
        provider.metrics.failedCount++;
      }
      return const <CompletionItem>[];
    }).toList();

    final lists = await Future.wait(futures);
    for (final list in lists) {
      results.addAll(list);
    }

    final seen = <String>{};
    final unique = <CompletionItem>[];
    for (final item in results) {
      if (!seen.contains(item.label)) {
        seen.add(item.label);
        unique.add(item);
      }
    }

    completionCache.put(
      language,
      versionsString,
      path,
      revision,
      prefix,
      unique,
    );

    return OperationResult.ok(unique);
  }

  Future<OperationResult<SignatureHelp>> getSignatureHelp(
    LanguageContext context,
    SignatureTriggerKind triggerKind,
  ) async {
    signatureRequests++;
    final language = context.document.language;
    final path = context.document.path;
    final revision = context.document.version.localRevision;

    final provider = registry.getSignatureHelpProvider(language);
    if (provider == null) {
      return const OperationResult.fail(
        WorkbenchError(
          code: 'UNSUPPORTED_LANGUAGE',
          message: 'No signature help provider registered.',
        ),
      );
    }

    activeSignatureProvider = provider.id;

    String symbol = '';
    try {
      final pos = context.position;
      final lineContent = context.document.lines[pos.line - 1];
      final col = pos.column - 1;
      int openParen = -1;
      int depth = 0;
      for (int i = col - 1; i >= 0; i--) {
        if (lineContent[i] == ')') depth++;
        else if (lineContent[i] == '(') {
          depth--;
          if (depth < 0) {
            openParen = i;
            break;
          }
        }
      }
      if (openParen != -1) {
        int idx = openParen - 1;
        while (idx >= 0 && RegExp(r'\s').hasMatch(lineContent[idx])) {
          idx--;
        }
        int end = idx + 1;
        while (idx >= 0 && RegExp(r'[a-zA-Z0-9_.]').hasMatch(lineContent[idx])) {
          idx--;
        }
        symbol = lineContent.substring(idx + 1, end).trim();
      }
    } catch (_) {}

    final cached = signatureHelpCache.get(
      context.workspace,
      path,
      revision,
      symbol,
    );
    if (cached != null) {
      signatureCacheHits++;
      return OperationResult.ok(cached);
    }

    final req = LanguageRequest(
      id: 'sig-${DateTime.now().millisecondsSinceEpoch}',
      context: context,
      timeout: const Duration(seconds: 3),
    );

    final execCtx = ProviderExecutionContext(
      request: req,
      stopwatch: Stopwatch()..start(),
      metrics: provider.metrics,
      capabilities: registry.getCapabilities(language),
    );

    provider.metrics.requestCount++;

    try {
      final res = await provider
          .provideSignatureHelp(execCtx)
          .timeout(req.timeout);
      execCtx.stopwatch.stop();
      if (res.success && res.data != null) {
        provider.metrics.successCount++;
        provider.metrics.totalLatency += execCtx.stopwatch.elapsed;
        totalSignatureLatency += execCtx.stopwatch.elapsed;
        signatureHelpCache.put(
          context.workspace,
          path,
          revision,
          symbol,
          res.data!,
        );
      } else {
        provider.metrics.failedCount++;
      }
      return res;
    } on TimeoutException {
      signatureTimeouts++;
      provider.metrics.failedCount++;
      context.token.cancel();
      return const OperationResult.fail(
        WorkbenchError(
          code: 'TIMEOUT',
          message: 'Signature help request timed out.',
        ),
      );
    } catch (e) {
      provider.metrics.failedCount++;
      return OperationResult.fail(
        WorkbenchError(code: 'INTERNAL_ERROR', message: e.toString()),
      );
    }
  }

  Future<OperationResult<List<CodeAction>>> getCodeActions(
    LanguageContext context,
    List<String> diagnosticIds,
  ) async {
    codeActionRequests++;
    final language = context.document.language;
    final path = context.document.path;
    final revision = context.document.version.localRevision;

    final cached = codeActionCache.get(
      context.workspace,
      path,
      revision,
      context.position,
      diagnosticIds,
    );
    if (cached != null) {
      codeActionCacheHits++;
      return OperationResult.ok(cached);
    }

    final provider = registry.getCodeActionProvider(language);
    if (provider == null) {
      return const OperationResult.ok([]);
    }

    activeCodeActionProvider = provider.id;

    final req = LanguageRequest(
      id: 'code-action-${DateTime.now().millisecondsSinceEpoch}',
      context: context,
      timeout: const Duration(seconds: 3),
    );

    final execCtx = ProviderExecutionContext(
      request: req,
      stopwatch: Stopwatch()..start(),
      metrics: provider.metrics,
      capabilities: registry.getCapabilities(language),
    );

    provider.metrics.requestCount++;

    try {
      final res = await provider
          .provideCodeActions(execCtx)
          .timeout(req.timeout);
      execCtx.stopwatch.stop();
      if (res.success && res.data != null) {
        provider.metrics.successCount++;
        provider.metrics.totalLatency += execCtx.stopwatch.elapsed;
        totalCodeActionLatency += execCtx.stopwatch.elapsed;
        codeActionCache.put(
          context.workspace,
          path,
          revision,
          context.position,
          diagnosticIds,
          res.data!,
        );
      } else {
        provider.metrics.failedCount++;
      }
      return res;
    } on TimeoutException {
      codeActionTimeouts++;
      provider.metrics.failedCount++;
      context.token.cancel();
      return const OperationResult.fail(
        WorkbenchError(
          code: 'TIMEOUT',
          message: 'Code action request timed out.',
        ),
      );
    } catch (e) {
      provider.metrics.failedCount++;
      return OperationResult.fail(
        WorkbenchError(code: 'INTERNAL_ERROR', message: e.toString()),
      );
    }
  }

  void recordAppliedAction(String kind, Duration latency) {
    codeActionsApplied++;
    totalCodeActionApplyTime += latency;
  }

  void recordFailedAction(String kind) {
    codeActionsFailed++;
  }
}
