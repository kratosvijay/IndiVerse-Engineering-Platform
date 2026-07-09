import 'knowledge_item.dart';
import 'knowledge_manager.dart';

class KnowledgeIndexer {
  // Classifies a workspace file and registers it in the KnowledgeManager
  Future<void> indexWorkspaceFile({
    required String filePath,
    required String content,
    required KnowledgeManager manager,
  }) async {
    final lowerPath = filePath.toLowerCase();
    KnowledgeCategory category;

    if (lowerPath.endsWith('readme.md')) {
      category = KnowledgeCategory.readme;
    } else if (lowerPath.contains('adr') ||
        lowerPath.contains('architecture')) {
      category = KnowledgeCategory.adr;
    } else if (lowerPath.contains('docs/') ||
        lowerPath.contains('documentation/')) {
      category = KnowledgeCategory.documentation;
    } else if (lowerPath.contains('test/')) {
      category = KnowledgeCategory.testPattern;
    } else {
      category = KnowledgeCategory.architecture;
    }

    final doc = KnowledgeDocument(
      id: 'doc_${filePath.hashCode}',
      title: filePath.split('/').last,
      content: content,
      summary: 'Auto-indexed repository document.',
      source: filePath,
      category: category,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await manager.insertDocument(doc);
  }
}
