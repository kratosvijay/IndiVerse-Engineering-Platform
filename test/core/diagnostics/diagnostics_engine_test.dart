import 'package:test/test.dart';
import 'package:indiverse_developer_platform/core/diagnostics/diagnostic_models.dart';
import 'package:indiverse_developer_platform/core/diagnostics/diagnostics_engine.dart';

void main() {
  group('Diagnostics Engine & Rules Tests', () {
    late DiagnosticsEngine engine;

    setUp(() {
      engine = DiagnosticsEngine();
    });

    test('DartSyntaxRule detects brace mismatch', () {
      final doc = DocumentSnapshot(
        path: 'lib/test.dart',
        content:
            'void main() {\n  if (true) {\n    print("hello");\n}', // missing closing brace
        revision: 1,
      );
      final diags = engine.run(doc);
      expect(diags.any((d) => d.code == 'DART_SYNTAX_MISMATCH'), isTrue);
      expect(diags.first.severity, DiagnosticSeverity.error);
    });

    test('DartSyntaxRule passes on correct braces', () {
      final doc = DocumentSnapshot(
        path: 'lib/test.dart',
        content: 'void main() {\n  if (true) {\n    print("hello");\n  }\n}',
        revision: 1,
      );
      final diags = engine.run(doc);
      expect(diags.any((d) => d.code == 'DART_SYNTAX_MISMATCH'), isFalse);
    });

    test('DartDeprecationRule detects withOpacity warning', () {
      final doc = DocumentSnapshot(
        path: 'lib/test.dart',
        content: 'final color = Colors.black.withOpacity(0.5);',
        revision: 1,
      );
      final diags = engine.run(doc);
      expect(
          diags.any((d) => d.code == 'DART_DEPRECATED_WITH_OPACITY'), isTrue);
      expect(diags.first.severity, DiagnosticSeverity.warning);
      expect(diags.first.tags.contains(DiagnosticTag.deprecated), isTrue);
    });

    test('JsonSyntaxRule detects trailing comma and unquoted key', () {
      final doc1 = DocumentSnapshot(
        path: 'test.json',
        content: '{\n  "name": "john",\n}', // trailing comma
        revision: 1,
      );
      final diags1 = engine.run(doc1);
      expect(diags1.any((d) => d.code == 'JSON_TRAILING_COMMA'), isTrue);

      final doc2 = DocumentSnapshot(
        path: 'test.json',
        content: '{\n  unquotedKey: "value"\n}', // unquoted key
        revision: 1,
      );
      final diags2 = engine.run(doc2);
      expect(diags2.any((d) => d.code == 'JSON_UNQUOTED_KEY'), isTrue);
    });

    test('YamlIndentationRule detects tab character usage', () {
      final doc = DocumentSnapshot(
        path: 'config.yaml',
        content: 'services:\n\tweb:\n    image: nginx', // tab
        revision: 1,
      );
      final diags = engine.run(doc);
      expect(diags.any((d) => d.code == 'YAML_TAB_CHARACTER'), isTrue);
    });

    test('GenericTodoRule detects TODO and FIXME', () {
      final doc = DocumentSnapshot(
        path: 'lib/test.dart',
        content: '// TODO: implement feature\n// FIXME: fix this bug',
        revision: 1,
      );
      final diags = engine.run(doc);
      expect(diags.where((d) => d.code == 'GENERIC_TODO_MARKER').length, 2);
      expect(diags.first.severity, DiagnosticSeverity.information);
    });
  });
}
