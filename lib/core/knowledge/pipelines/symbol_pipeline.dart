import '../contracts/symbol_extractor.dart';
import '../models/symbol.dart';

class SymbolPipeline {
  final List<SymbolExtractor> extractors;

  SymbolPipeline({required this.extractors});

  Future<List<SymbolModel>> extract(
      String content, String sourcePath, String language) async {
    final extractor = extractors.firstWhere(
      (e) => e.language == language,
      orElse: () => _DefaultExtractor(language),
    );
    return await extractor.extract(content, sourcePath);
  }
}

class _DefaultExtractor implements SymbolExtractor {
  @override
  final String language;

  _DefaultExtractor(this.language);

  @override
  Future<List<SymbolModel>> extract(String content, String sourcePath) async =>
      [];
}
