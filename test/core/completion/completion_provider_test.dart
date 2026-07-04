import 'package:test/test.dart';
import 'package:indiverse_developer_platform/core/diagnostics/diagnostic_models.dart';
import 'package:indiverse_developer_platform/core/diagnostics/completion_provider.dart';
import 'package:indiverse_developer_platform/core/studio/services/code_intelligence_service.dart';

void main() {
  group('Autocomplete Contributors and Engine Tests', () {
    test('KeywordContributor returns language-specific keywords', () {
      final contributor = KeywordContributor();
      final doc = DocumentSnapshot(
        path: 'lib/main.dart',
        content: '',
        revision: 1,
      );

      final results = contributor.getCompletions(
          doc, const Position(line: 1, column: 1), 'pr');
      expect(results.any((item) => item.label == 'print'), isTrue);
      expect(results.every((item) => item.kind == CompletionItemKind.keyword),
          isTrue);

      final resultsJson = contributor.getCompletions(
        DocumentSnapshot(path: 'config.json', content: '', revision: 1),
        const Position(line: 1, column: 1),
        'tr',
      );
      expect(resultsJson.any((item) => item.label == 'true'), isTrue);
    });

    test('ScopeContributor extracts local identifiers and index symbols', () {
      final symbolIndex = SymbolIndex();
      final contributor = ScopeContributor(symbolIndex: symbolIndex);

      final doc = DocumentSnapshot(
        path: 'lib/main.dart',
        content:
            'void main() {\n  final myVariable = 42;\n  print(myVariable);\n}',
        revision: 1,
      );

      final results = contributor.getCompletions(
          doc, const Position(line: 3, column: 1), 'my');
      expect(results.any((item) => item.label == 'myVariable'), isTrue);
      expect(results.first.kind, CompletionItemKind.variable);
    });

    test('SnippetContributor suggests boilerplate templates', () {
      final contributor = SnippetContributor();
      final doc = DocumentSnapshot(
        path: 'lib/main.dart',
        content: '',
        revision: 1,
      );

      final results = contributor.getCompletions(
          doc, const Position(line: 1, column: 1), 'fo');
      expect(results.any((item) => item.label == 'for'), isTrue);
      expect(results.firstWhere((item) => item.label == 'for').insertTextFormat,
          2);
    });
  });
}
