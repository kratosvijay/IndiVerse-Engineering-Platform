import 'dart:async';
import '../../models/language_intelligence_models.dart';
import 'language_intelligence_providers.dart';
import 'language_provider_registry.dart';
import 'workbench_providers.dart';

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

  LanguageIntelligenceService(this.registry);

  void invalidateCache(String path) {
    _hoverCache.removeWhere((key, val) => key.documentId == path);
    _semanticTokensCache.removeWhere((key, val) => key.documentId == path);
    _diagnosticsCache.removeWhere((key, val) => key.documentId == path);
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
  ) async {
    final language = context.document.language;
    final provider = registry.getCompletionProvider(language);
    if (provider == null) {
      return const OperationResult.fail(
        WorkbenchError(
          code: 'UNSUPPORTED_LANGUAGE',
          message: 'No completion provider registered.',
        ),
      );
    }

    final req = LanguageRequest(
      id: 'completion-${DateTime.now().millisecondsSinceEpoch}',
      context: context,
      timeout: const Duration(milliseconds: 250),
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
          .provideCompletions(execCtx)
          .timeout(req.timeout);
      execCtx.stopwatch.stop();
      if (res.success) {
        provider.metrics.successCount++;
        provider.metrics.totalLatency += execCtx.stopwatch.elapsed;
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
          message: 'Completion request timed out.',
        ),
      );
    } catch (e) {
      provider.metrics.failedCount++;
      return OperationResult.fail(
        WorkbenchError(code: 'INTERNAL_ERROR', message: e.toString()),
      );
    }
  }
}
