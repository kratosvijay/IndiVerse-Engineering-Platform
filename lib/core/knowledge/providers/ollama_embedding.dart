import '../contracts/embedding_provider.dart';

class OllamaEmbeddingProvider implements EmbeddingProvider {
  @override
  String get name => "ollama";
  @override
  String get provider => "ollama";
  @override
  String get model => "nomic-embed-text";
  @override
  int get dimensions => 768;
  @override
  int get maxTokens => 2048;
  @override
  bool get supportsBatch => true;
  @override
  bool get supportsAsync => true;

  @override
  Future<List<double>> getEmbedding(String text) async {
    final list =
        List<double>.generate(768, (i) => (text.hashCode - i) % 100 / 100.0);
    return list;
  }
}
