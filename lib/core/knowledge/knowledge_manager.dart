import 'embedding_provider.dart';
import 'vector_store.dart';
import 'knowledge_item.dart';
import 'document_chunker.dart';

class KnowledgeManager {
  final KnowledgeStore store = KnowledgeStore();
  final VectorStore vectorStore;
  final EmbeddingProvider embeddingProvider;
  final DocumentChunker chunker = DocumentChunker();

  KnowledgeManager({
    required this.vectorStore,
    required this.embeddingProvider,
  });

  // Inserts a canonical document, chunks it, embeds each chunk, and indexes in VectorStore
  Future<void> insertDocument(KnowledgeDocument doc) async {
    store.add(doc);
    final chunks = chunker.chunk(doc);

    for (final chunk in chunks) {
      final embedding = await embeddingProvider.embedText(chunk.text);
      final item = VectorItem(
        id: chunk.chunkId,
        embedding: embedding,
        payload: {
          'documentId': doc.id,
          'category': doc.category.name,
          'text': chunk.text,
        },
      );
      await vectorStore.insert(item);
    }
  }

  Future<void> deleteDocument(String id) async {
    final doc = store.get(id);
    if (doc == null) return;

    store.remove(id);
    final chunks = chunker.chunk(doc);
    for (final chunk in chunks) {
      await vectorStore.delete(chunk.chunkId);
    }
  }

  Future<void> updateDocument(KnowledgeDocument doc) async {
    await deleteDocument(doc.id);
    await insertDocument(doc);
  }
}

class KnowledgeStore {
  final Map<String, KnowledgeDocument> _documents = {};

  void add(KnowledgeDocument doc) {
    _documents[doc.id] = doc;
  }

  void remove(String id) {
    _documents.remove(id);
  }

  KnowledgeDocument? get(String id) => _documents[id];
  List<KnowledgeDocument> get all => List.unmodifiable(_documents.values);
  void clear() => _documents.clear();
}

class KnowledgeManagerRegistry {
  static KnowledgeManager? _active;
  static KnowledgeManager? get active => _active;
  static set active(KnowledgeManager? manager) => _active = manager;

  static final Map<String, KnowledgeManager> _registry = {};
  static void register(String workspaceId, KnowledgeManager manager) {
    _registry[workspaceId] = manager;
    _active ??= manager;
  }

  static KnowledgeManager? get(String workspaceId) => _registry[workspaceId];
  static void clear() {
    _registry.clear();
    _active = null;
  }
}
