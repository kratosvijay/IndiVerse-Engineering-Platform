enum KnowledgeCategory {
  adr,
  documentation,
  readme,
  api,
  conversation,
  execution,
  reflection,
  bugFix,
  architecture,
  codePattern,
  testPattern,
  userPreference
}

class KnowledgeDocument {
  final String id;
  final String title;
  final String content;
  final String summary;
  final String source;
  final KnowledgeCategory category;
  final String language;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> metadata;

  const KnowledgeDocument({
    required this.id,
    required this.title,
    required this.content,
    required this.summary,
    required this.source,
    required this.category,
    this.language = 'dart',
    required this.createdAt,
    required this.updatedAt,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'summary': summary,
        'source': source,
        'category': category.name,
        'language': language,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'metadata': metadata,
      };

  factory KnowledgeDocument.fromJson(Map<String, dynamic> json) => KnowledgeDocument(
        id: json['id'] as String,
        title: json['title'] as String,
        content: json['content'] as String,
        summary: json['summary'] as String,
        source: json['source'] as String,
        category: KnowledgeCategory.values.firstWhere((e) => e.name == json['category']),
        language: json['language'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        metadata: json['metadata'] as Map<String, dynamic>,
      );
}

class KnowledgeChunk {
  final String documentId;
  final String chunkId;
  final String text;
  final int startOffset;
  final int endOffset;
  final int tokenEstimate;

  const KnowledgeChunk({
    required this.documentId,
    required this.chunkId,
    required this.text,
    required this.startOffset,
    required this.endOffset,
    required this.tokenEstimate,
  });

  Map<String, dynamic> toJson() => {
        'documentId': documentId,
        'chunkId': chunkId,
        'text': text,
        'startOffset': startOffset,
        'endOffset': endOffset,
        'tokenEstimate': tokenEstimate,
      };

  factory KnowledgeChunk.fromJson(Map<String, dynamic> json) => KnowledgeChunk(
        documentId: json['documentId'] as String,
        chunkId: json['chunkId'] as String,
        text: json['text'] as String,
        startOffset: json['startOffset'] as int,
        endOffset: json['endOffset'] as int,
        tokenEstimate: json['tokenEstimate'] as int,
      );
}
