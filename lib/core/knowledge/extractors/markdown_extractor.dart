import '../contracts/symbol_extractor.dart';
import '../models/symbol.dart';

class MarkdownExtractor implements SymbolExtractor {
  @override
  String get language => "markdown";

  @override
  Future<List<SymbolModel>> extract(String content, String sourcePath) async {
    return [];
  }
}
