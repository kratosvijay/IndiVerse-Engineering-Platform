import '../diagnostics/diagnostic_models.dart';

class CodeActionProvider {
  List<CodeAction> getCodeActions(
    DocumentSnapshot document,
    Range selection,
    List<Diagnostic> diagnostics,
  ) {
    final actions = <CodeAction>[];

    // Always check for Organize Imports in Dart files
    if (document.path.endsWith('.dart')) {
      final organizeEdit = _generateOrganizeImportsEdit(document);
      if (organizeEdit != null) {
        actions.add(CodeAction(
          id: 'organize-imports-${DateTime.now().millisecondsSinceEpoch}',
          title: 'Organize Imports',
          kind: CodeActionKind.sourceOrganizeImports,
          edit: organizeEdit,
        ));
      }
    }

    // Filter diagnostics that intersect with selection
    final intersecting =
        diagnostics.where((d) => _rangeOverlaps(d.range, selection)).toList();

    // Map intersecting diagnostics to quick fixes
    final List<CodeAction> quickFixes = [];
    for (final diag in intersecting) {
      final fix = _generateQuickFix(document, diag);
      if (fix != null) {
        quickFixes.add(fix);
      }
    }
    actions.addAll(quickFixes);

    // If there are multiple quick fixes in the document, generate "Fix All" action
    final allFixes = <CodeAction>[];
    for (final diag in diagnostics) {
      final fix = _generateQuickFix(document, diag);
      if (fix != null) {
        allFixes.add(fix);
      }
    }

    if (allFixes.length > 1) {
      final mergedEdit = _mergeCodeActions(allFixes);
      actions.add(CodeAction(
        id: 'fix-all-${DateTime.now().millisecondsSinceEpoch}',
        title: 'Fix All',
        kind: CodeActionKind.sourceFixAll,
        edit: mergedEdit,
        isPreferred: true,
      ));
    }

    return actions;
  }

  bool _rangeOverlaps(Range r1, Range r2) {
    if (_comparePosition(r1.end, r2.start) < 0) return false;
    if (_comparePosition(r2.end, r1.start) < 0) return false;
    return true;
  }

  int _comparePosition(Position p1, Position p2) {
    if (p1.line != p2.line) return p1.line.compareTo(p2.line);
    return p1.column.compareTo(p2.column);
  }

  WorkspaceEdit? _generateOrganizeImportsEdit(DocumentSnapshot doc) {
    final lines = doc.lines;
    final importRegex = RegExp(r'^\s*import\s+["\x27].*["\x27];');
    final importIndices = <int>[];
    final importTexts = <String>[];

    for (int i = 0; i < lines.length; i++) {
      if (importRegex.hasMatch(lines[i])) {
        importIndices.add(i + 1);
        importTexts.add(lines[i]);
      }
    }

    if (importIndices.isEmpty) return null;

    final sortedTexts = List<String>.from(importTexts)..sort();
    final edits = <TextEdit>[];

    for (int i = 0; i < importIndices.length; i++) {
      final lineIdx = importIndices[i];
      edits.add(TextEdit(
        range: Range(
          start: Position(line: lineIdx, column: 1),
          end: Position(line: lineIdx, column: lines[lineIdx - 1].length + 1),
        ),
        newText: sortedTexts[i],
      ));
    }

    return WorkspaceEdit(changes: {doc.path: edits});
  }

  CodeAction? _generateQuickFix(DocumentSnapshot doc, Diagnostic diag) {
    final code = diag.code.toLowerCase();
    final msg = diag.message.toLowerCase();

    if (code == 'unused_variable' || msg.contains('unused')) {
      return CodeAction(
        id: 'fix-unused-${diag.id}',
        title: 'Remove variable',
        kind: CodeActionKind.quickFix,
        isPreferred: true,
        diagnostics: [diag],
        edit: WorkspaceEdit(changes: {
          doc.path: [
            TextEdit(range: diag.range, newText: ''),
          ],
        }),
      );
    }

    if (code == 'dart_deprecated_with_opacity' || msg.contains('deprecated')) {
      String replacement = 'withValues';
      final match = RegExp(r"Use '([^']+)' instead", caseSensitive: false)
          .firstMatch(diag.message);
      if (match != null) {
        replacement = match.group(1)!;
      }
      return CodeAction(
        id: 'fix-deprecated-${diag.id}',
        title: 'Replace with $replacement',
        kind: CodeActionKind.quickFix,
        isPreferred: true,
        diagnostics: [diag],
        edit: WorkspaceEdit(changes: {
          doc.path: [
            TextEdit(range: diag.range, newText: replacement),
          ],
        }),
      );
    }

    if (code == 'generic_todo_marker' || msg.contains('todo')) {
      final lineIdx = diag.range.start.line;
      if (lineIdx > 0 && lineIdx <= doc.lines.length) {
        final lineText = doc.lines[lineIdx - 1];
        final todoIdx = lineText.toUpperCase().indexOf('TODO');
        if (todoIdx != -1) {
          final range = Range(
            start: Position(line: lineIdx, column: todoIdx + 1),
            end: Position(line: lineIdx, column: todoIdx + 5),
          );
          return CodeAction(
            id: 'fix-todo-${diag.id}',
            title: 'Mark as completed',
            kind: CodeActionKind.quickFix,
            diagnostics: [diag],
            edit: WorkspaceEdit(changes: {
              doc.path: [
                TextEdit(range: range, newText: 'COMPLETED'),
              ],
            }),
          );
        }
      }
    }

    if (code == 'missing_import' || msg.contains('import')) {
      return CodeAction(
        id: 'fix-import-${diag.id}',
        title: 'Add import',
        kind: CodeActionKind.quickFix,
        diagnostics: [diag],
        edit: WorkspaceEdit(changes: {
          doc.path: [
            const TextEdit(
              range: Range(
                start: Position(line: 1, column: 1),
                end: Position(line: 1, column: 1),
              ),
              newText: "import 'package:flutter/material.dart';\n",
            ),
          ],
        }),
      );
    }

    if (code == 'json_unquoted_key' || msg.contains('quotes')) {
      final lineIdx = diag.range.start.line;
      if (lineIdx > 0 && lineIdx <= doc.lines.length) {
        final lineText = doc.lines[lineIdx - 1];
        final keyText = lineText.substring(
            diag.range.start.column - 1, diag.range.end.column - 1);
        return CodeAction(
          id: 'fix-json-quotes-${diag.id}',
          title: 'Fix quotes',
          kind: CodeActionKind.quickFix,
          isPreferred: true,
          diagnostics: [diag],
          edit: WorkspaceEdit(changes: {
            doc.path: [
              TextEdit(range: diag.range, newText: '"$keyText"'),
            ],
          }),
        );
      }
    }

    if (code == 'json_trailing_comma') {
      return CodeAction(
        id: 'fix-json-comma-${diag.id}',
        title: 'Remove trailing comma',
        kind: CodeActionKind.quickFix,
        isPreferred: true,
        diagnostics: [diag],
        edit: WorkspaceEdit(changes: {
          doc.path: [
            TextEdit(range: diag.range, newText: ''),
          ],
        }),
      );
    }

    if (code == 'yaml_tab_character' || msg.contains('tabs')) {
      return CodeAction(
        id: 'fix-yaml-tabs-${diag.id}',
        title: 'Convert tabs to spaces',
        kind: CodeActionKind.quickFix,
        isPreferred: true,
        diagnostics: [diag],
        edit: WorkspaceEdit(changes: {
          doc.path: [
            TextEdit(range: diag.range, newText: '  '),
          ],
        }),
      );
    }

    return null;
  }

  WorkspaceEdit _mergeCodeActions(List<CodeAction> actions) {
    final mergedChanges = <String, List<TextEdit>>{};

    for (final action in actions) {
      if (action.edit == null) continue;
      action.edit!.changes.forEach((path, edits) {
        mergedChanges.putIfAbsent(path, () => []).addAll(edits);
      });
    }

    // Sort edits by descending offset to prevent overlaps/shifting
    mergedChanges.forEach((path, edits) {
      edits.sort((a, b) => _comparePosition(b.range.start, a.range.start));
    });

    return WorkspaceEdit(changes: mergedChanges);
  }
}
