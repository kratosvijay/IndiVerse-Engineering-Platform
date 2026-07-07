import 'package:test/test.dart';
import 'package:indiverse_developer_platform/core/code_actions/code_action_provider.dart';
import 'package:indiverse_developer_platform/core/diagnostics/diagnostic_models.dart';

void main() {
  group('Backend Code Actions & Quick Fixes Tests', () {
    late CodeActionProvider provider;

    setUp(() {
      provider = CodeActionProvider();
    });

    test('Organize Imports sorts imports alphabetically', () {
      final doc = DocumentSnapshot(
        path: 'lib/main.dart',
        content:
            "import 'c.dart';\nimport 'a.dart';\nimport 'b.dart';\n\nvoid main() {}",
        revision: 1,
      );

      final actions = provider.getCodeActions(
        doc,
        Range(
          start: const Position(line: 1, column: 1),
          end: const Position(line: 1, column: 1),
        ),
        [],
      );
      final organizeAction = actions
          .firstWhere((a) => a.kind == CodeActionKind.sourceOrganizeImports);

      expect(organizeAction, isNotNull);
      expect(organizeAction.title, equals('Organize Imports'));
      expect(organizeAction.edit, isNotNull);

      final edits = organizeAction.edit!.changes['lib/main.dart']!;
      expect(edits.length, equals(3));
      expect(edits[0].newText, equals("import 'a.dart';"));
      expect(edits[1].newText, equals("import 'b.dart';"));
      expect(edits[2].newText, equals("import 'c.dart';"));
    });

    test('Unused variable quick fix generates correct removal text edit', () {
      final doc = DocumentSnapshot(
        path: 'lib/main.dart',
        content: "void main() {\n  var x = 42;\n}",
        revision: 1,
      );

      final diag = Diagnostic(
        id: 'unused-x',
        range: Range(
          start: const Position(line: 2, column: 7),
          end: const Position(line: 2, column: 8),
        ),
        severity: DiagnosticSeverity.warning,
        message: "The variable 'x' isn't used.",
        code: 'unused_variable',
        source: 'test',
      );

      final actions = provider.getCodeActions(
        doc,
        Range(
          start: const Position(line: 2, column: 7),
          end: const Position(line: 2, column: 8),
        ),
        [diag],
      );
      final fixAction =
          actions.firstWhere((a) => a.kind == CodeActionKind.quickFix);

      expect(fixAction.title, equals('Remove variable'));
      expect(fixAction.isPreferred, isTrue);
      expect(
          fixAction.edit!.changes['lib/main.dart']!.first.newText, equals(''));
    });

    test('Deprecated API quick fix parses replacement and returns edit', () {
      final doc = DocumentSnapshot(
        path: 'lib/main.dart',
        content: "var c = Color.withOpacity(0.5);",
        revision: 1,
      );

      final diag = Diagnostic(
        id: 'deprecated-opac',
        range: Range(
          start: const Position(line: 1, column: 15),
          end: const Position(line: 1, column: 26),
        ),
        severity: DiagnosticSeverity.warning,
        message: "'withOpacity' is deprecated. Use 'withValues' instead.",
        code: 'dart_deprecated_with_opacity',
        source: 'test',
      );

      final actions = provider.getCodeActions(
        doc,
        Range(
          start: const Position(line: 1, column: 16),
          end: const Position(line: 1, column: 16),
        ),
        [diag],
      );
      final fixAction =
          actions.firstWhere((a) => a.title.contains('withValues'));

      expect(fixAction.isPreferred, isTrue);
      expect(fixAction.edit!.changes['lib/main.dart']!.first.newText,
          equals('withValues'));
    });

    test('Fix All merges multiple fixes and sorts in descending order', () {
      final doc = DocumentSnapshot(
        path: 'lib/main.dart',
        content: "void main() {\n  var x = 42;\n  var y = 24;\n}",
        revision: 1,
      );

      final diagX = Diagnostic(
        id: 'unused-x',
        range: Range(
          start: const Position(line: 2, column: 7),
          end: const Position(line: 2, column: 8),
        ),
        severity: DiagnosticSeverity.warning,
        message: "The variable 'x' isn't used.",
        code: 'unused_variable',
        source: 'test',
      );

      final diagY = Diagnostic(
        id: 'unused-y',
        range: Range(
          start: const Position(line: 3, column: 7),
          end: const Position(line: 3, column: 8),
        ),
        severity: DiagnosticSeverity.warning,
        message: "The variable 'y' isn't used.",
        code: 'unused_variable',
        source: 'test',
      );

      final actions = provider.getCodeActions(
        doc,
        Range(
          start: const Position(line: 2, column: 1),
          end: const Position(line: 3, column: 10),
        ),
        [diagX, diagY],
      );

      final fixAllAction =
          actions.firstWhere((a) => a.kind == CodeActionKind.sourceFixAll);
      expect(fixAllAction.title, equals('Fix All'));

      final edits = fixAllAction.edit!.changes['lib/main.dart']!;
      expect(edits.length, equals(2));

      expect(edits[0].range.start.line, equals(3));
      expect(edits[1].range.start.line, equals(2));
    });
  });
}
