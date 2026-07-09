import 'package:test/test.dart';
import 'package:indiverse_developer_platform/core/knowledge/embedding_provider.dart';
import 'package:indiverse_developer_platform/core/knowledge/vector_store.dart';
import 'package:indiverse_developer_platform/core/knowledge/knowledge_item.dart';
import 'package:indiverse_developer_platform/core/knowledge/document_chunker.dart';
import 'package:indiverse_developer_platform/core/knowledge/knowledge_manager.dart';
import 'package:indiverse_developer_platform/core/knowledge/retriever_pipeline.dart';
import 'package:indiverse_developer_platform/core/knowledge/knowledge_indexer.dart';
import 'package:indiverse_developer_platform/core/knowledge/memory_manager.dart';
import 'package:indiverse_developer_platform/core/agent/runtime/reflection_context.dart';
import 'package:indiverse_developer_platform/core/agent/runtime/reflection_result.dart';
import 'package:indiverse_developer_platform/core/agent/runtime/reflection_strategy.dart';
import 'package:indiverse_developer_platform/core/agent/workflow/execution_state.dart';
import 'package:indiverse_developer_platform/core/agent/workflow/task_step.dart';
import 'package:indiverse_developer_platform/core/agent/workflow/task_graph.dart';
import 'package:indiverse_developer_platform/core/prompt/prompt_pipeline.dart';
import 'package:indiverse_developer_platform/core/models/tool_call_models.dart';
import 'package:indiverse_developer_platform/core/studio/services/tool_handler.dart';
import 'package:indiverse_developer_platform/core/studio/services/tool_registry.dart';
import 'package:indiverse_developer_platform/core/studio/services/permission_store.dart';
import 'package:indiverse_developer_platform/core/studio/services/tool_execution_service.dart';
import 'package:indiverse_developer_platform/core/studio/services/tools/knowledge_tools.dart';
import 'package:indiverse_developer_platform/platform_sdk/platform_sdk.dart';
import 'package:indiverse_developer_platform/platform_sdk/runtime_api.dart';
import 'package:indiverse_developer_platform/platform_sdk/workspace_api.dart';
import 'package:indiverse_developer_platform/platform_sdk/knowledge_api.dart';
import 'package:indiverse_developer_platform/platform_sdk/agent_api.dart';
import 'package:indiverse_developer_platform/platform_sdk/plugin_api.dart';

class TestToolRegistry extends ToolRegistry {}

class TestPermissionStore extends ToolPermissionStore {
  @override
  PermissionDecision? getDecision(String toolName) => null;
}

void main() {
  group('Sprint 22.0 - Long-Term Knowledge and Persistent Memory Tests', () {
    late MockEmbeddingProvider embeddingProvider;
    late MemoryVectorStore vectorStore;
    late KnowledgeManager knowledgeManager;
    late DocumentChunker chunker;

    setUp(() {
      embeddingProvider = const MockEmbeddingProvider(dimensions: 8);
      vectorStore = MemoryVectorStore();
      knowledgeManager = KnowledgeManager(
        vectorStore: vectorStore,
        embeddingProvider: embeddingProvider,
      );
      chunker = DocumentChunker();

      KnowledgeManagerRegistry.clear();
      KnowledgeManagerRegistry.register('test-ws', knowledgeManager);
    });

    test(
        'Embeddings provider generates normalized dimension-consistent vectors',
        () async {
      final text =
          'Clean architecture dependencies are strictly unidirectional.';
      final embedding = await embeddingProvider.embedText(text);

      expect(embedding.dimensions, equals(8));
      expect(embedding.vector, hasLength(8));

      // Assert vector is normalized (magnitude should be very close to 1.0)
      var sumOfSquares = 0.0;
      for (final val in embedding.vector) {
        sumOfSquares += val * val;
      }
      expect(sumOfSquares, closeTo(1.0, 0.01));
    });

    test('DocumentChunker splits text and preserves offsets and estimations',
        () {
      final doc = KnowledgeDocument(
        id: 'doc-1',
        title: 'Architectural Rules',
        content:
            'Rule 1: Domain layer must be pure. Rule 2: UI depends only on Controllers.',
        summary: 'Workspace boundaries.',
        source: 'docs/ADR.md',
        category: KnowledgeCategory.adr,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final chunks = chunker.chunk(doc, chunkSize: 30, chunkOverlap: 5);
      expect(chunks, isNotEmpty);
      expect(chunks.first.documentId, equals('doc-1'));
      expect(chunks.first.startOffset, equals(0));
      expect(chunks.first.endOffset, greaterThan(0));
      expect(chunks.first.tokenEstimate, greaterThan(0));
    });

    test('MemoryVectorStore performs correct cosine nearestNeighbors query',
        () async {
      final embedA = await embeddingProvider
          .embedText('Riverpod state notifier initialization');
      final embedB = await embeddingProvider
          .embedText('Sqlite local storage bindings configuration');
      final queryEmbed =
          await embeddingProvider.embedText('Riverpod notifier state');

      await vectorStore.insert(
          VectorItem(id: 'item-a', embedding: embedA, payload: const {}));
      await vectorStore.insert(
          VectorItem(id: 'item-b', embedding: embedB, payload: const {}));

      final results = await vectorStore.search(queryEmbed, limit: 1);
      expect(results, hasLength(1));
      expect(results.first.item.id, equals('item-a'));
      expect(results.first.score, greaterThan(0.5));
    });

    test(
        'KnowledgeManager inserts, deletes, and updates canonical doc mappings',
        () async {
      final doc = KnowledgeDocument(
        id: 'doc-2',
        title: 'Api Endpoints',
        content: 'GET /api/v1/auth validates tokens.',
        summary: 'Authentication paths.',
        source: 'lib/routes.dart',
        category: KnowledgeCategory.api,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await knowledgeManager.insertDocument(doc);
      expect(knowledgeManager.store.get('doc-2'), isNotNull);

      // Verify chunks indexed in VectorStore
      final queryEmbed = await embeddingProvider.embedText('/api/v1/auth');
      final results = await vectorStore.search(queryEmbed, limit: 10);
      expect(results, isNotEmpty);
      expect(
          results.any((r) => r.item.payload['documentId'] == 'doc-2'), isTrue);

      // Delete document
      await knowledgeManager.deleteDocument('doc-2');
      expect(knowledgeManager.store.get('doc-2'), isNull);

      final resultsPostDelete = await vectorStore.search(queryEmbed, limit: 10);
      expect(
          resultsPostDelete.any((r) => r.item.payload['documentId'] == 'doc-2'),
          isFalse);
    });

    test('RetrieverPipeline returns ranked context summaries', () async {
      final doc = KnowledgeDocument(
        id: 'doc-3',
        title: 'Riverside riverpod pattern',
        content: 'Standard state notifier pattern is X.',
        summary: 'Riverpod notifier patterns.',
        source: 'docs/RiversideRiverpod.md',
        category: KnowledgeCategory.codePattern,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await knowledgeManager.insertDocument(doc);

      final pipeline = RetrieverPipeline(manager: knowledgeManager);
      final contextText = await pipeline
          .retrieveAndBuildContext('state notifier pattern', minScore: 0.1);
      expect(contextText, contains('Riverside riverpod pattern'));
      expect(contextText, contains('Standard state notifier pattern is X.'));
    });

    test(
        'KnowledgeIndexer classifies and indexes README, ADR, and test patterns',
        () async {
      final indexer = KnowledgeIndexer();

      await indexer.indexWorkspaceFile(
        filePath: 'docs/ADR01.md',
        content: 'Use final variables for entities.',
        manager: knowledgeManager,
      );

      final doc = knowledgeManager.store.all.first;
      expect(doc.title, equals('ADR01.md'));
      expect(doc.category, equals(KnowledgeCategory.adr));
    });

    test('MemoryManager stores segmented facts', () {
      final manager = MemoryManager();
      final doc = KnowledgeDocument(
        id: 'doc-mem',
        title: 'Temporary Exec Fact',
        content: 'Task step completed with exit code 0.',
        summary: 'Execution log.',
        source: 'execution',
        category: KnowledgeCategory.execution,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      manager.save(MemorySegment.temporary, doc);
      expect(manager.get(MemorySegment.temporary), hasLength(1));
      expect(manager.get(MemorySegment.project), isEmpty);
    });

    test(
        'KnowledgeReflectionStrategy evaluates history before planning retries',
        () async {
      final doc = KnowledgeDocument(
        id: 'doc-err',
        title: 'Compiler fix',
        content: 'Import path failed. Fix: update prompt_pipeline paths.',
        summary: 'Resolution log.',
        source: 'failure',
        category: KnowledgeCategory.reflection,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await knowledgeManager.insertDocument(doc);

      final pipeline = RetrieverPipeline(manager: knowledgeManager);
      final strategy = KnowledgeReflectionStrategy(retriever: pipeline);

      final step = const TaskStep(id: 'step-1', title: 'Write prompt builder');
      final stepState = const StepExecutionState(stepId: 'step-1').copyWith(
        status: StepStatus.failed,
        retryCount: 0,
      );

      final context = ReflectionContext(
        goal: 'Mock goal',
        session: ExecutionSession(
          executionId: 'exec-1',
          planId: 'plan-1',
          graph: const TaskGraph(id: 'g-1', goal: 'test', steps: []),
          stepStates: const {},
          startedAt: DateTime.now(),
        ),
        activeStep: step,
        stepState: stepState,
        lastFailure: 'prompt_pipeline path failed',
      );

      expect(strategy.matches(context), isTrue);

      final result = await strategy.evaluate(context);
      expect(result.decision, equals(ReflectionDecision.retryCurrentStep));
      expect(result.reasoning, contains('Fix: update prompt_pipeline paths.'));
    });

    test('Knowledge search and insert tools execute successfully', () async {
      final registry = TestToolRegistry();
      registry.register(KnowledgeSearchTool());
      registry.register(KnowledgeInsertTool());

      final service = ToolExecutionService(
        registry: registry,
        permissionStore: TestPermissionStore(),
      );

      final sdk = PlatformSDK(
        runtime: RuntimeAPI(),
        workspace: WorkspaceAPI(),
        knowledge: KnowledgeAPI(),
        agent: AgentAPI(),
        plugin: PluginAPI(),
      );

      final context = ToolExecutionContext(
        workspaceId: 'test-ws',
        conversationId: 'conv-1',
        requestId: 'req-1',
        providerId: 'prov-1',
        modelId: 'mod-1',
        cancellationToken: CancellationToken(),
        sdk: sdk,
      );

      final requestInsert = const ToolCallRequest(
        toolCallId: 'call-ins',
        toolName: 'knowledge.insert',
        arguments: {
          'id': 'doc-tool',
          'title': 'Tool Documentation',
          'content': 'How to invoke permission checks.',
          'category': 'documentation',
        },
      );

      final resInsert = await service.execute(requestInsert, context);
      expect(resInsert.success, isTrue);

      final requestSearch = const ToolCallRequest(
        toolCallId: 'call-sea',
        toolName: 'knowledge.search',
        arguments: {'query': 'permission checks'},
      );

      final resSearch = await service.execute(requestSearch, context);
      expect(resSearch.success, isTrue);
      expect(resSearch.output.displayText, contains('Found'));
    });
  });
}
