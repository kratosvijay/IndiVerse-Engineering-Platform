import 'dart:math';

class Embedding {
  final String provider;
  final String model;
  final List<double> vector;
  final int dimensions;

  const Embedding({
    required this.provider,
    required this.model,
    required this.vector,
    required this.dimensions,
  });

  Map<String, dynamic> toJson() => {
        'provider': provider,
        'model': model,
        'vector': vector,
        'dimensions': dimensions,
      };

  factory Embedding.fromJson(Map<String, dynamic> json) => Embedding(
        provider: json['provider'] as String,
        model: json['model'] as String,
        vector: List<double>.from(json['vector'] as List),
        dimensions: json['dimensions'] as int,
      );
}

abstract class EmbeddingProvider {
  Future<Embedding> embedText(String text);
}

class MockEmbeddingProvider implements EmbeddingProvider {
  final String provider;
  final String model;
  final int dimensions;

  const MockEmbeddingProvider({
    this.provider = 'mock',
    this.model = 'mock-embed-v1',
    this.dimensions = 8,
  });

  @override
  Future<Embedding> embedText(String text) async {
    // Generate deterministic, normalized vector based on character code distribution
    final vector = List<double>.filled(dimensions, 0.0);
    if (text.isEmpty) {
      vector[0] = 1.0;
      return Embedding(provider: provider, model: model, vector: vector, dimensions: dimensions);
    }

    for (int i = 0; i < text.length; i++) {
      final code = text.codeUnitAt(i);
      vector[i % dimensions] += code.toDouble();
    }

    // Normalize the vector
    var sumOfSquares = 0.0;
    for (final val in vector) {
      sumOfSquares += val * val;
    }
    final magnitude = sqrt(sumOfSquares);
    if (magnitude > 0.0) {
      for (int i = 0; i < dimensions; i++) {
        vector[i] /= magnitude;
      }
    } else {
      vector[0] = 1.0;
    }

    return Embedding(
      provider: provider,
      model: model,
      vector: vector,
      dimensions: dimensions,
    );
  }
}
