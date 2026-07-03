abstract class EmbeddingProvider {
  String get name;
  String get provider;
  String get model;
  int get dimensions;
  int get maxTokens;
  bool get supportsBatch;
  bool get supportsAsync;

  Future<List<double>> getEmbedding(String text);
}
