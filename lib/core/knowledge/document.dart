class Document {
  final String id;
  final String uri;
  final String content;
  final String language;
  final String checksum;
  final Map<String, dynamic> metadata;

  const Document({
    required this.id,
    required this.uri,
    required this.content,
    required this.language,
    required this.checksum,
    required this.metadata,
  });
}
