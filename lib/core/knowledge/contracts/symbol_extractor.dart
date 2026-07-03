import '../models/symbol.dart';

abstract class SymbolExtractor {
  String get language;
  Future<List<SymbolModel>> extract(String content, String sourcePath);
}
