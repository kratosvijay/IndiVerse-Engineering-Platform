import '../contracts/embedding_provider.dart';

class GeminiEmbeddingProvider implements EmbeddingProvider {
  @override
  String get name => "gemini";
  @override
  String get provider => "google";
  @override
  String get model => "text-embedding-004";
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
        List<double>.generate(768, (i) => (text.hashCode + i) % 100 / 100.0);
    return list;
  }
}
