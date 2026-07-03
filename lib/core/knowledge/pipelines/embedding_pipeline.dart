import '../contracts/embedding_provider.dart';

class EmbeddingPipeline {
  final EmbeddingProvider provider;

  EmbeddingPipeline({required this.provider});

  Future<List<double>> embed(String text) async {
    return await provider.getEmbedding(text);
  }
}
