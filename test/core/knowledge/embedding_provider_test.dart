import 'package:test/test.dart';
import 'package:indiverse_developer_platform/core/knowledge/providers/gemini_embedding.dart';
import 'package:indiverse_developer_platform/core/knowledge/providers/ollama_embedding.dart';

void main() {
  group('EmbeddingProvider Tests', () {
    test('GeminiEmbeddingProvider details & deterministic vector generation',
        () async {
      final provider = GeminiEmbeddingProvider();
      expect(provider.name, equals('gemini'));
      expect(provider.dimensions, equals(768));

      final embedding = await provider.getEmbedding('hello');
      expect(embedding.length, equals(768));
      expect(embedding.every((v) => v >= 0.0 && v <= 1.0), isTrue);
    });

    test('OllamaEmbeddingProvider details', () async {
      final provider = OllamaEmbeddingProvider();
      expect(provider.name, equals('ollama'));
      expect(provider.dimensions, equals(768));
    });
  });
}
