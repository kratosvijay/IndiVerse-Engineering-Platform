import 'package:test/test.dart';
import 'package:indiverse_developer_platform/core/knowledge/extractors/dart_extractor.dart';

void main() {
  group('SymbolExtractor Tests', () {
    test('DartExtractor regex class extraction', () async {
      final extractor = DartExtractor();
      const code = 'class MyService {}';
      final symbols = await extractor.extract(code, 'lib/service.dart');

      expect(symbols.length, equals(1));
      expect(symbols[0].name, equals('MyService'));
      expect(symbols[0].kind, equals('class'));
    });
  });
}
