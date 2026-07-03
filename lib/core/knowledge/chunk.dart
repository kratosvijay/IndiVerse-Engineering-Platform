class Chunk {
  final String id;
  final String documentId;
  final int startLine;
  final int endLine;
  final String content;
  final String checksum;
  final String language;
  final List<String> symbolIds;
  final int tokenCount;
  final Map<String, dynamic> metadata;

  const Chunk({
    required this.id,
    required this.documentId,
    required this.startLine,
    required this.endLine,
    required this.content,
    required this.checksum,
    required this.language,
    required this.symbolIds,
    required this.tokenCount,
    required this.metadata,
  });
}
