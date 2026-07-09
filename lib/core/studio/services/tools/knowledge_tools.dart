import '../../../models/tool_call_models.dart';
import '../tool_handler.dart';
import '../../../knowledge/knowledge_item.dart';
import '../../../knowledge/knowledge_manager.dart';
import '../../../knowledge/retriever_pipeline.dart';

class KnowledgeSearchTool implements ToolHandler {
  @override
  final ToolDescriptor descriptor = const ToolDescriptor(
    id: 'knowledge.search',
    name: 'Search Knowledge Base',
    description: 'Queries the vector store for semantic matches.',
    category: ToolCategory.workspace,
    requiresPermission: false,
    readOnly: true,
    destructive: false,
    modifiesWorkspace: false,
    tags: ['knowledge', 'rag', 'search'],
  );

  @override
  Future<ToolCallResult> execute(
      ToolCallRequest request, ToolExecutionContext context) async {
    final stopwatch = Stopwatch()..start();
    final query = request.arguments['query'] as String? ?? '';

    final manager = KnowledgeManagerRegistry.active ??
        KnowledgeManagerRegistry.get(context.workspaceId);

    if (manager == null) {
      return ToolCallResult(
        success: false,
        output: const ToolOutput(
            displayText: 'Knowledge Manager not initialized.',
            mimeType: 'text/plain'),
        duration: stopwatch.elapsed,
        errorCode: 'KNOWLEDGE_NOT_INITIALIZED',
      );
    }

    final pipeline = RetrieverPipeline(manager: manager);
    final results = await pipeline.retrieve(query, limit: 3);

    return ToolCallResult(
      success: true,
      output: ToolOutput(
        data: {
          'items': results
              .map((r) => {
                    'chunkId': r.item.id,
                    'documentId': r.item.payload['documentId'],
                    'text': r.item.payload['text'],
                    'score': r.score,
                  })
              .toList(),
        },
        displayText:
            'Found ${results.length} relevant context chunks matching "$query".',
        mimeType: 'application/json',
      ),
      duration: stopwatch.elapsed,
    );
  }
}

class KnowledgeInsertTool implements ToolHandler {
  @override
  final ToolDescriptor descriptor = const ToolDescriptor(
    id: 'knowledge.insert',
    name: 'Insert Knowledge Document',
    description: 'Registers a new knowledge document in the store.',
    category: ToolCategory.workspace,
    requiresPermission: false,
    readOnly: false,
    destructive: false,
    modifiesWorkspace: false,
    tags: ['knowledge', 'insert'],
  );

  @override
  Future<ToolCallResult> execute(
      ToolCallRequest request, ToolExecutionContext context) async {
    final stopwatch = Stopwatch()..start();
    final id = request.arguments['id'] as String? ??
        'doc_${DateTime.now().millisecondsSinceEpoch}';
    final title = request.arguments['title'] as String? ?? 'Untitled Document';
    final content = request.arguments['content'] as String? ?? '';
    final categoryName =
        request.arguments['category'] as String? ?? 'documentation';

    final category = KnowledgeCategory.values.firstWhere(
      (e) => e.name == categoryName,
      orElse: () => KnowledgeCategory.documentation,
    );

    final manager = KnowledgeManagerRegistry.active ??
        KnowledgeManagerRegistry.get(context.workspaceId);

    if (manager == null) {
      return ToolCallResult(
        success: false,
        output: const ToolOutput(
            displayText: 'Knowledge Manager not initialized.',
            mimeType: 'text/plain'),
        duration: stopwatch.elapsed,
        errorCode: 'KNOWLEDGE_NOT_INITIALIZED',
      );
    }

    final doc = KnowledgeDocument(
      id: id,
      title: title,
      content: content,
      summary: 'Manually inserted document.',
      source: 'manual',
      category: category,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await manager.insertDocument(doc);

    return ToolCallResult(
      success: true,
      output: ToolOutput(
        displayText: 'Document "$title" successfully inserted and indexed.',
        mimeType: 'text/plain',
      ),
      duration: stopwatch.elapsed,
    );
  }
}

class KnowledgeUpdateTool implements ToolHandler {
  @override
  final ToolDescriptor descriptor = const ToolDescriptor(
    id: 'knowledge.update',
    name: 'Update Knowledge Document',
    description: 'Updates an existing knowledge document.',
    category: ToolCategory.workspace,
    requiresPermission: false,
    readOnly: false,
    destructive: false,
    modifiesWorkspace: false,
    tags: ['knowledge', 'update'],
  );

  @override
  Future<ToolCallResult> execute(
      ToolCallRequest request, ToolExecutionContext context) async {
    final stopwatch = Stopwatch()..start();
    final id = request.arguments['id'] as String? ?? '';
    final title = request.arguments['title'] as String? ?? 'Updated Title';
    final content = request.arguments['content'] as String? ?? '';
    final categoryName =
        request.arguments['category'] as String? ?? 'documentation';

    final category = KnowledgeCategory.values.firstWhere(
      (e) => e.name == categoryName,
      orElse: () => KnowledgeCategory.documentation,
    );

    final manager = KnowledgeManagerRegistry.active ??
        KnowledgeManagerRegistry.get(context.workspaceId);

    if (manager == null) {
      return ToolCallResult(
        success: false,
        output: const ToolOutput(
            displayText: 'Knowledge Manager not initialized.',
            mimeType: 'text/plain'),
        duration: stopwatch.elapsed,
        errorCode: 'KNOWLEDGE_NOT_INITIALIZED',
      );
    }

    final doc = KnowledgeDocument(
      id: id,
      title: title,
      content: content,
      summary: 'Manually updated document.',
      source: 'manual',
      category: category,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await manager.updateDocument(doc);

    return ToolCallResult(
      success: true,
      output: ToolOutput(
        displayText: 'Document "$id" successfully updated and re-indexed.',
        mimeType: 'text/plain',
      ),
      duration: stopwatch.elapsed,
    );
  }
}

class KnowledgeDeleteTool implements ToolHandler {
  @override
  final ToolDescriptor descriptor = const ToolDescriptor(
    id: 'knowledge.delete',
    name: 'Delete Knowledge Document',
    description: 'Removes a document and its chunks from the store.',
    category: ToolCategory.workspace,
    requiresPermission: false,
    readOnly: false,
    destructive: true,
    modifiesWorkspace: false,
    tags: ['knowledge', 'delete'],
  );

  @override
  Future<ToolCallResult> execute(
      ToolCallRequest request, ToolExecutionContext context) async {
    final stopwatch = Stopwatch()..start();
    final id = request.arguments['id'] as String? ?? '';

    final manager = KnowledgeManagerRegistry.active ??
        KnowledgeManagerRegistry.get(context.workspaceId);

    if (manager == null) {
      return ToolCallResult(
        success: false,
        output: const ToolOutput(
            displayText: 'Knowledge Manager not initialized.',
            mimeType: 'text/plain'),
        duration: stopwatch.elapsed,
        errorCode: 'KNOWLEDGE_NOT_INITIALIZED',
      );
    }

    await manager.deleteDocument(id);

    return ToolCallResult(
      success: true,
      output: ToolOutput(
        displayText: 'Document "$id" successfully deleted.',
        mimeType: 'text/plain',
      ),
      duration: stopwatch.elapsed,
    );
  }
}

class KnowledgeHistoryTool implements ToolHandler {
  @override
  final ToolDescriptor descriptor = const ToolDescriptor(
    id: 'knowledge.history',
    name: 'Knowledge History',
    description: 'Lists all indexed knowledge documents.',
    category: ToolCategory.workspace,
    requiresPermission: false,
    readOnly: true,
    destructive: false,
    modifiesWorkspace: false,
    tags: ['knowledge', 'history'],
  );

  @override
  Future<ToolCallResult> execute(
      ToolCallRequest request, ToolExecutionContext context) async {
    final stopwatch = Stopwatch()..start();

    final manager = KnowledgeManagerRegistry.active ??
        KnowledgeManagerRegistry.get(context.workspaceId);

    if (manager == null) {
      return ToolCallResult(
        success: false,
        output: const ToolOutput(
            displayText: 'Knowledge Manager not initialized.',
            mimeType: 'text/plain'),
        duration: stopwatch.elapsed,
        errorCode: 'KNOWLEDGE_NOT_INITIALIZED',
      );
    }

    final docs = manager.store.all;

    return ToolCallResult(
      success: true,
      output: ToolOutput(
        data: {
          'items': docs.map((d) => d.toJson()).toList(),
        },
        displayText: 'Total indexed documents: ${docs.length}.',
        mimeType: 'application/json',
      ),
      duration: stopwatch.elapsed,
    );
  }
}

class KnowledgeSimilarTool implements ToolHandler {
  @override
  final ToolDescriptor descriptor = const ToolDescriptor(
    id: 'knowledge.similar',
    name: 'Find Similar Chunks',
    description: 'Retrieves semantically similar items using a chunk content.',
    category: ToolCategory.workspace,
    requiresPermission: false,
    readOnly: true,
    destructive: false,
    modifiesWorkspace: false,
    tags: ['knowledge', 'similarity'],
  );

  @override
  Future<ToolCallResult> execute(
      ToolCallRequest request, ToolExecutionContext context) async {
    final stopwatch = Stopwatch()..start();
    final text = request.arguments['text'] as String? ?? '';

    final manager = KnowledgeManagerRegistry.active ??
        KnowledgeManagerRegistry.get(context.workspaceId);

    if (manager == null) {
      return ToolCallResult(
        success: false,
        output: const ToolOutput(
            displayText: 'Knowledge Manager not initialized.',
            mimeType: 'text/plain'),
        duration: stopwatch.elapsed,
        errorCode: 'KNOWLEDGE_NOT_INITIALIZED',
      );
    }

    final queryEmbedding = await manager.embeddingProvider.embedText(text);
    final results = await manager.vectorStore.search(queryEmbedding, limit: 3);

    return ToolCallResult(
      success: true,
      output: ToolOutput(
        data: {
          'items': results.map((r) => r.item.toJson()).toList(),
        },
        displayText: 'Found ${results.length} similar chunks.',
        mimeType: 'application/json',
      ),
      duration: stopwatch.elapsed,
    );
  }
}

class KnowledgeLearnTool implements ToolHandler {
  @override
  final ToolDescriptor descriptor = const ToolDescriptor(
    id: 'knowledge.learn',
    name: 'Learn Execution Fact',
    description:
        'Records lessons learned, planning failures, or coding patterns.',
    category: ToolCategory.workspace,
    requiresPermission: false,
    readOnly: false,
    destructive: false,
    modifiesWorkspace: false,
    tags: ['knowledge', 'learn'],
  );

  @override
  Future<ToolCallResult> execute(
      ToolCallRequest request, ToolExecutionContext context) async {
    final stopwatch = Stopwatch()..start();
    final lesson = request.arguments['lesson'] as String? ?? '';
    final id = 'lesson_${DateTime.now().millisecondsSinceEpoch}';

    final manager = KnowledgeManagerRegistry.active ??
        KnowledgeManagerRegistry.get(context.workspaceId);

    if (manager == null) {
      return ToolCallResult(
        success: false,
        output: const ToolOutput(
            displayText: 'Knowledge Manager not initialized.',
            mimeType: 'text/plain'),
        duration: stopwatch.elapsed,
        errorCode: 'KNOWLEDGE_NOT_INITIALIZED',
      );
    }

    final doc = KnowledgeDocument(
      id: id,
      title: 'Lessons Learned: $id',
      content: lesson,
      summary: 'Automatically learned fact during execution run.',
      source: 'agent_runtime',
      category: KnowledgeCategory.reflection,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await manager.insertDocument(doc);

    return ToolCallResult(
      success: true,
      output: ToolOutput(
        displayText: 'Successfully recorded execution lesson: "$id".',
        mimeType: 'text/plain',
      ),
      duration: stopwatch.elapsed,
    );
  }
}

class KnowledgeRelatedTool implements ToolHandler {
  @override
  final ToolDescriptor descriptor = const ToolDescriptor(
    id: 'knowledge.related',
    name: 'Find Related Documents',
    description: 'Finds document titles related to query.',
    category: ToolCategory.workspace,
    requiresPermission: false,
    readOnly: true,
    destructive: false,
    modifiesWorkspace: false,
    tags: ['knowledge', 'related'],
  );

  @override
  Future<ToolCallResult> execute(
      ToolCallRequest request, ToolExecutionContext context) async {
    final stopwatch = Stopwatch()..start();
    final query = request.arguments['query'] as String? ?? '';

    final manager = KnowledgeManagerRegistry.active ??
        KnowledgeManagerRegistry.get(context.workspaceId);

    if (manager == null) {
      return ToolCallResult(
        success: false,
        output: const ToolOutput(
            displayText: 'Knowledge Manager not initialized.',
            mimeType: 'text/plain'),
        duration: stopwatch.elapsed,
        errorCode: 'KNOWLEDGE_NOT_INITIALIZED',
      );
    }

    final pipeline = RetrieverPipeline(manager: manager);
    final results = await pipeline.retrieve(query, limit: 3);
    final docs = results
        .map((r) {
          final docId = r.item.payload['documentId'] as String;
          return manager.store.get(docId)?.title ?? 'Untitled';
        })
        .toSet()
        .toList();

    return ToolCallResult(
      success: true,
      output: ToolOutput(
        data: {'documents': docs},
        displayText: 'Related documents: ${docs.join(", ")}.',
        mimeType: 'application/json',
      ),
      duration: stopwatch.elapsed,
    );
  }
}

class KnowledgeSummarizeTool implements ToolHandler {
  @override
  final ToolDescriptor descriptor = const ToolDescriptor(
    id: 'knowledge.summarize',
    name: 'Summarize Document',
    description: 'Retrieves a document summary.',
    category: ToolCategory.workspace,
    requiresPermission: false,
    readOnly: true,
    destructive: false,
    modifiesWorkspace: false,
    tags: ['knowledge', 'summary'],
  );

  @override
  Future<ToolCallResult> execute(
      ToolCallRequest request, ToolExecutionContext context) async {
    final stopwatch = Stopwatch()..start();
    final id = request.arguments['id'] as String? ?? '';

    final manager = KnowledgeManagerRegistry.active ??
        KnowledgeManagerRegistry.get(context.workspaceId);

    if (manager == null) {
      return ToolCallResult(
        success: false,
        output: const ToolOutput(
            displayText: 'Knowledge Manager not initialized.',
            mimeType: 'text/plain'),
        duration: stopwatch.elapsed,
        errorCode: 'KNOWLEDGE_NOT_INITIALIZED',
      );
    }

    final doc = manager.store.get(id);
    if (doc == null) {
      return ToolCallResult(
        success: false,
        output: const ToolOutput(
            displayText: 'Document not found.', mimeType: 'text/plain'),
        duration: stopwatch.elapsed,
        errorCode: 'DOCUMENT_NOT_FOUND',
      );
    }

    return ToolCallResult(
      success: true,
      output: ToolOutput(
        data: {'summary': doc.summary},
        displayText: doc.summary,
        mimeType: 'application/json',
      ),
      duration: stopwatch.elapsed,
    );
  }
}

class KnowledgeReindexTool implements ToolHandler {
  @override
  final ToolDescriptor descriptor = const ToolDescriptor(
    id: 'knowledge.reindex',
    name: 'Reindex Knowledge Store',
    description: 'Reindexes all documents.',
    category: ToolCategory.workspace,
    requiresPermission: false,
    readOnly: false,
    destructive: false,
    modifiesWorkspace: false,
    tags: ['knowledge', 'reindex'],
  );

  @override
  Future<ToolCallResult> execute(
      ToolCallRequest request, ToolExecutionContext context) async {
    final stopwatch = Stopwatch()..start();

    final manager = KnowledgeManagerRegistry.active ??
        KnowledgeManagerRegistry.get(context.workspaceId);

    if (manager == null) {
      return ToolCallResult(
        success: false,
        output: const ToolOutput(
            displayText: 'Knowledge Manager not initialized.',
            mimeType: 'text/plain'),
        duration: stopwatch.elapsed,
        errorCode: 'KNOWLEDGE_NOT_INITIALIZED',
      );
    }

    final allDocs = List<KnowledgeDocument>.from(manager.store.all);
    await manager.vectorStore.clear();

    for (final doc in allDocs) {
      await manager.insertDocument(doc);
    }

    return ToolCallResult(
      success: true,
      output: ToolOutput(
        displayText: 'Successfully reindexed ${allDocs.length} documents.',
        mimeType: 'text/plain',
      ),
      duration: stopwatch.elapsed,
    );
  }
}
