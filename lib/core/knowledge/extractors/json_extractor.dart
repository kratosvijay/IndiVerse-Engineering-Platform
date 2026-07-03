import '../contracts/symbol_extractor.dart';
import '../models/symbol.dart';

class JsonExtractor implements SymbolExtractor {
  @override
  String get language => "json";

  @override
  Future<List<SymbolModel>> extract(String content, String sourcePath) async {
    return [];
  }
}
