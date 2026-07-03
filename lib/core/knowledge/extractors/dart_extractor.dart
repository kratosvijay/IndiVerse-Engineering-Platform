import '../contracts/symbol_extractor.dart';
import '../models/symbol.dart';

class DartExtractor implements SymbolExtractor {
  @override
  String get language => "dart";

  @override
  Future<List<SymbolModel>> extract(String content, String sourcePath) async {
    final symbols = <SymbolModel>[];
    final classRegex = RegExp(r'class\s+(\w+)');
    for (final match in classRegex.allMatches(content)) {
      final name = match.group(1)!;
      symbols.add(SymbolModel(
        id: "$sourcePath-$name",
        name: name,
        kind: "class",
        filePath: sourcePath,
      ));
    }
    return symbols;
  }
}
