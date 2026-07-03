import '../document.dart';

class DocumentPipeline {
  Future<Document> load(String uri, String content,
      {String language = "dart"}) async {
    final checksum = content.hashCode.toString();
    return Document(
      id: uri,
      uri: uri,
      content: content,
      language: language,
      checksum: checksum,
      metadata: const {},
    );
  }
}
