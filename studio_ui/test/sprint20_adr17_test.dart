import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/core/services/language_intelligence_providers.dart';
import 'package:studio_ui/core/services/language_provider_registry.dart';
import 'package:studio_ui/core/services/language_intelligence_service.dart';
import 'package:studio_ui/models/language_intelligence_models.dart';
import 'package:studio_ui/models/editor_document.dart';
import 'package:studio_ui/core/services/workbench_providers.dart';

class MockHoverProvider implements HoverProvider {
  @override
  final String id;
  @override
  final String language;
  @override
  final int version;

  @override
  int priority;

  @override
  ProviderState state = ProviderState.ready;

  @override
  final ProviderMetrics metrics = ProviderMetrics();

  bool initialized = false;
  bool started = false;
  bool stopped = false;
  bool disposed = false;
  final Duration delay;
  final Hover result;

  MockHoverProvider({
    required this.id,
    required this.language,
    this.version = 1,
    required this.priority,
    required this.result,
    this.delay = Duration.zero,
  });

  @override
  Future<void> initialize() async {
    initialized = true;
  }

  @override
  Future<void> start() async {
    started = true;
  }

  @override
  Future<void> stop() async {
    stopped = true;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
  }

  @override
  Future<OperationResult<Hover>> provideHover(
    ProviderExecutionContext context,
  ) async {
    if (delay > Duration.zero) {
      await Future.delayed(delay);
    }
    if (context.request.context.token.isCancelled) {
      return const OperationResult.fail(
        WorkbenchError(code: 'CANCELLED', message: 'Request cancelled.'),
      );
    }
    return OperationResult.ok(result);
  }
}

void main() {
  group('LanguageProviderRegistry Tests', () {
    test('Provider registration prioritizes LSP over Regex', () async {
      final registry = LanguageProviderRegistry();
      final regex = MockHoverProvider(
        id: 'regex-hover',
        language: 'dart',
        priority: 1,
        result: const Hover(contents: 'Regex Doc'),
      );
      final lsp = MockHoverProvider(
        id: 'lsp-hover',
        language: 'dart',
        priority: 10,
        result: const Hover(contents: 'LSP Doc'),
      );

      await registry.registerHoverProvider('dart', regex);
      await registry.registerHoverProvider('dart', lsp);

      expect(registry.getHoverProvider('dart')?.id, 'lsp-hover');
      expect(regex.initialized && regex.started, true);
      expect(lsp.initialized && lsp.started, true);
    });

    test('Capability metadata discovery reports correctly', () async {
      final registry = LanguageProviderRegistry();
      final hoverProv = MockHoverProvider(
        id: 'hover-prov',
        language: 'yaml',
        priority: 5,
        result: const Hover(contents: 'Yaml Doc'),
      );

      await registry.registerHoverProvider('yaml', hoverProv);
      final caps = registry.getCapabilities('yaml');

      expect(caps.hover, true);
      expect(caps.completion, false);
    });
  });

  group('LanguageIntelligenceService Orchestration Tests', () {
    late LanguageProviderRegistry registry;
    late LanguageIntelligenceService service;
    late EditorDocument doc;

    setUp(() {
      registry = LanguageProviderRegistry();
      service = LanguageIntelligenceService(registry);
      doc = EditorDocument(
        id: 'main.dart',
        path: 'main.dart',
        name: 'main.dart',
        content: 'void main() {}',
        language: 'dart',
        encoding: 'utf8',
        lastModified: '',
        readOnly: false,
      );
    });

    test('Cancellations and request timeouts', () async {
      final slowLsp = MockHoverProvider(
        id: 'slow-lsp',
        language: 'dart',
        priority: 10,
        result: const Hover(contents: 'Slow Doc'),
        delay: const Duration(seconds: 1),
      );

      await registry.registerHoverProvider('dart', slowLsp);

      final token = CancellationToken();
      final ctx = LanguageContext(
        document: doc,
        position: const Position(line: 1, column: 1),
        workspace: 'test',
        workspaceRevision: 1,
        token: token,
      );

      final start = DateTime.now();
      final res = await service.getHover(ctx);
      final elapsed = DateTime.now().difference(start);

      expect(res.success, false);
      expect(res.error?.code, 'TIMEOUT');
      expect(token.isCancelled, true);
      expect(elapsed.inMilliseconds < 800, true);
    });

    test('Caching & Invalidation logic', () async {
      final fastLsp = MockHoverProvider(
        id: 'fast-lsp',
        language: 'dart',
        priority: 10,
        result: const Hover(contents: 'Doc V1'),
      );

      await registry.registerHoverProvider('dart', fastLsp);

      final token = CancellationToken();
      final ctx = LanguageContext(
        document: doc,
        position: const Position(line: 1, column: 1),
        workspace: 'test',
        workspaceRevision: 1,
        token: token,
      );

      final res1 = await service.getHover(ctx);
      expect(res1.success, true);
      expect(res1.data?.contents, 'Doc V1');

      expect(fastLsp.metrics.requestCount, 1);
      expect(fastLsp.metrics.successCount, 1);

      final res2 = await service.getHover(ctx);
      expect(res2.success, true);
      expect(fastLsp.metrics.requestCount, 1);

      doc.replaceBuffer('void main() { print("hello"); }');
      final ctx2 = LanguageContext(
        document: doc,
        position: const Position(line: 1, column: 1),
        workspace: 'test',
        workspaceRevision: 1,
        token: CancellationToken(),
      );

      final res3 = await service.getHover(ctx2);
      expect(res3.success, true);
      expect(fastLsp.metrics.requestCount, 2);
    });
  });
}
