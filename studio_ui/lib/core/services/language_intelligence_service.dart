import 'dart:async';
import '../../models/language_intelligence_models.dart';
import 'language_intelligence_providers.dart';
import 'language_provider_registry.dart';
import 'workbench_providers.dart';
import 'completion_cache.dart';

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

  // Metric fields for autocomplete
  int completionRequests = 0;
  int completionCacheHits = 0;

  LanguageIntelligenceService(this.registry);

  void invalidateCache(String path) {
    _hoverCache.removeWhere((key, val) => key.documentId == path);
    _semanticTokensCache.removeWhere((key, val) => key.documentId == path);
    _diagnosticsCache.removeWhere((key, val) => key.documentId == path);
    completionCache.invalidatePath(path);
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
}
