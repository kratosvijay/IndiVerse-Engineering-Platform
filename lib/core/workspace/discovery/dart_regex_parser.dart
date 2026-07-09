import 'dart:convert';
import '../graph/workspace_symbol.dart';
import '../graph/dependency_graph.dart';
import '../graph/call_graph.dart';
import '../index/build_intelligence.dart';
import 'language_parser.dart';

class DartRegexParser implements LanguageParser {
  @override
  WorkspaceParseResult parse(String filePath, String content) {
    final symbols = <WorkspaceSymbol>[];
    final imports = <Map<String, dynamic>>[];
    final calls = <Map<String, dynamic>>[];
    final diagnostics = <BuildDiagnostic>[];

    final lines = LineSplitter.split(content).toList();

    // 1. Extract Imports, Exports, Parts
    final importRegex = RegExp(r"^\s*import\s+[' font]*([^';]+)[' font]*");
    final exportRegex = RegExp(r"^\s*export\s+[' font]*([^';]+)[' font]*");
    final partRegex = RegExp(r"^\s*part\s+[' font]*([^';]+)[' font]*");
    final partOfRegex = RegExp(r"^\s*part\s+of\s+[' font]*([^';]+)[' font]*");

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      var match = importRegex.firstMatch(line);
      if (match != null) {
        var path =
            match.group(1)?.replaceAll("'", "").replaceAll('"', "").trim() ??
                '';
        if (path.isNotEmpty) {
          imports.add({'target': path, 'type': DependencyType.importRelation});
        }
        continue;
      }

      match = exportRegex.firstMatch(line);
      if (match != null) {
        var path =
            match.group(1)?.replaceAll("'", "").replaceAll('"', "").trim() ??
                '';
        if (path.isNotEmpty) {
          imports.add({'target': path, 'type': DependencyType.exportRelation});
        }
        continue;
      }

      match = partOfRegex.firstMatch(line);
      if (match != null) {
        var path =
            match.group(1)?.replaceAll("'", "").replaceAll('"', "").trim() ??
                '';
        if (path.isNotEmpty) {
          imports.add({'target': path, 'type': DependencyType.partOfRelation});
        }
        continue;
      }

      match = partRegex.firstMatch(line);
      if (match != null) {
        var path =
            match.group(1)?.replaceAll("'", "").replaceAll('"', "").trim() ??
                '';
        if (path.isNotEmpty) {
          imports.add({'target': path, 'type': DependencyType.partRelation});
        }
        continue;
      }
    }

    // 2. Extract Symbols (Classes, Mixins, Enums, Typedefs, Extensions, and Methods)
    final classRegex = RegExp(
        r"^\s*(?:abstract\s+|base\s+|interface\s+|final\s+|sealed\s+)?class\s+([a-zA-Z0-9_<>]+)");
    final mixinRegex = RegExp(r"^\s*mixin\s+([a-zA-Z0-9_]+)");
    final enumRegex = RegExp(r"^\s*enum\s+([a-zA-Z0-9_]+)");
    final typedefRegex = RegExp(r"^\s*typedef\s+([a-zA-Z0-9_<>]+)\s*=");
    final extensionRegex = RegExp(r"^\s*extension\s+([a-zA-Z0-9_]+)?\s+on\s+");

    // Simplistic method/field match within lines
    final methodRegex = RegExp(
        r"^\s*(?:@\w+\s+)*(?:async\s+|static\s+|factory\s+|external\s+)*([a-zA-Z0-9_<>]+)\s+([a-zA-Z0-9_]+)\s*\(([^)]*)\)");

    WorkspaceSymbol? currentParent;
    String? activeMethodId;
    var depth = 0;
    final parentChildrenMap = <String, List<String>>{};
    final annotationsAccumulator = <String>[];
    String? docAccumulator;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineNum = i + 1;

      // Accumulate documentation comments
      if (line.trim().startsWith('///')) {
        final docLine = line.trim().substring(3).trim();
        docAccumulator =
            docAccumulator == null ? docLine : '$docAccumulator\n$docLine';
        continue;
      } else if (line.trim().startsWith('//')) {
        // regular comments, ignore docs but clean up if needed
        continue;
      }

      // Accumulate annotations
      if (line.trim().startsWith('@')) {
        final ann = line.trim().substring(1).split('(').first;
        annotationsAccumulator.add(ann);
        continue;
      }

      // Track brace depth inside class
      if (currentParent != null) {
        final openBraces = '{'.allMatches(line).length;
        final closeBraces = '}'.allMatches(line).length;
        depth += openBraces;
        depth -= closeBraces;
        if (depth <= 1) {
          activeMethodId = null;
        }
        if (depth <= 0) {
          currentParent = null;
          activeMethodId = null;
        }
      }

      // Identify major structural symbols
      var m = classRegex.firstMatch(line);
      if (m != null) {
        final name = m.group(1)!.split('<').first;
        final id = "workspace://$filePath#$name";
        final classSym = WorkspaceSymbol(
          id: id,
          name: name,
          kind: SymbolKind.classSymbol,
          visibility: name.startsWith('_')
              ? SymbolVisibility.private
              : SymbolVisibility.public,
          filePath: filePath,
          startLine: lineNum,
          endLine: lineNum + 10, // heuristic
          column: line.indexOf(name) + 1,
          annotations: List.from(annotationsAccumulator),
          documentation: docAccumulator,
          parentIds: const [],
          childrenIds: const [],
        );
        symbols.add(classSym);
        currentParent = classSym;
        depth = '{'.allMatches(line).length - '}'.allMatches(line).length;
        if (depth <= 0) {
          depth = 1; // heuristic minimum depth
        }
        parentChildrenMap[id] = [];
        docAccumulator = null;
        annotationsAccumulator.clear();
        continue;
      }

      m = mixinRegex.firstMatch(line);
      if (m != null) {
        final name = m.group(1)!;
        final id = "workspace://$filePath#$name";
        symbols.add(WorkspaceSymbol(
          id: id,
          name: name,
          kind: SymbolKind.mixin,
          visibility: name.startsWith('_')
              ? SymbolVisibility.private
              : SymbolVisibility.public,
          filePath: filePath,
          startLine: lineNum,
          endLine: lineNum + 5,
          column: line.indexOf(name) + 1,
          annotations: List.from(annotationsAccumulator),
          documentation: docAccumulator,
          parentIds: const [],
          childrenIds: const [],
        ));
        docAccumulator = null;
        annotationsAccumulator.clear();
        continue;
      }

      m = enumRegex.firstMatch(line);
      if (m != null) {
        final name = m.group(1)!;
        final id = "workspace://$filePath#$name";
        symbols.add(WorkspaceSymbol(
          id: id,
          name: name,
          kind: SymbolKind.enumSymbol,
          visibility: name.startsWith('_')
              ? SymbolVisibility.private
              : SymbolVisibility.public,
          filePath: filePath,
          startLine: lineNum,
          endLine: lineNum + 5,
          column: line.indexOf(name) + 1,
          annotations: List.from(annotationsAccumulator),
          documentation: docAccumulator,
          parentIds: const [],
          childrenIds: const [],
        ));
        docAccumulator = null;
        annotationsAccumulator.clear();
        continue;
      }

      m = typedefRegex.firstMatch(line);
      if (m != null) {
        final name = m.group(1)!.split('<').first;
        final id = "workspace://$filePath#$name";
        symbols.add(WorkspaceSymbol(
          id: id,
          name: name,
          kind: SymbolKind.typedefSymbol,
          visibility: name.startsWith('_')
              ? SymbolVisibility.private
              : SymbolVisibility.public,
          filePath: filePath,
          startLine: lineNum,
          endLine: lineNum,
          column: line.indexOf(name) + 1,
          annotations: List.from(annotationsAccumulator),
          documentation: docAccumulator,
          parentIds: const [],
          childrenIds: const [],
        ));
        docAccumulator = null;
        annotationsAccumulator.clear();
        continue;
      }

      m = extensionRegex.firstMatch(line);
      if (m != null) {
        final name = m.group(1) ?? "AnonymousExtension_${lineNum}";
        final id = "workspace://$filePath#$name";
        symbols.add(WorkspaceSymbol(
          id: id,
          name: name,
          kind: SymbolKind.extensionSymbol,
          visibility: name.startsWith('_')
              ? SymbolVisibility.private
              : SymbolVisibility.public,
          filePath: filePath,
          startLine: lineNum,
          endLine: lineNum + 5,
          column: line.indexOf(name) + 1,
          annotations: List.from(annotationsAccumulator),
          documentation: docAccumulator,
          parentIds: const [],
          childrenIds: const [],
        ));
        docAccumulator = null;
        annotationsAccumulator.clear();
        continue;
      }

      // Identify methods
      m = methodRegex.firstMatch(line);
      if (m != null) {
        final returnType = m.group(1)!;
        final name = m.group(2)!;

        // Skip common keywords misidentified as types/methods
        if (const {
          'if',
          'for',
          'while',
          'switch',
          'return',
          'else',
          'import',
          'export',
          'part',
          'class',
          'enum',
          'mixin'
        }.contains(returnType)) {
          continue;
        }

        final parentId = currentParent?.id;
        final id = parentId != null
            ? "$parentId.$name"
            : "workspace://$filePath#$name";

        final methodSymbol = WorkspaceSymbol(
          id: id,
          name: name,
          kind: SymbolKind.method,
          visibility: name.startsWith('_')
              ? SymbolVisibility.private
              : SymbolVisibility.public,
          filePath: filePath,
          startLine: lineNum,
          endLine: lineNum,
          column: line.indexOf(name) + 1,
          annotations: List.from(annotationsAccumulator),
          documentation: docAccumulator,
          parentIds: parentId != null ? [parentId] : const [],
          childrenIds: const [],
        );

        if (parentId != null) {
          parentChildrenMap[parentId]!.add(id);
        }
        symbols.add(methodSymbol);
        activeMethodId = id;

        docAccumulator = null;
        annotationsAccumulator.clear();
        continue;
      }

      // 3. Extract Calls (simple invocation matching inside this method block)
      if (activeMethodId != null) {
        final callRegex = RegExp(r"\b([a-zA-Z0-9_]+)\.([a-zA-Z0-9_]+)\(");
        final superCallRegex = RegExp(r"\bsuper\.([a-zA-Z0-9_]+)\(");
        final constructorRegex = RegExp(r"\bnew\s+([a-zA-Z0-9_]+)\(");

        for (final match in callRegex.allMatches(line)) {
          final instance = match.group(1)!;
          final method = match.group(2)!;
          if (instance != 'super' && instance != 'this') {
            calls.add({
              'callerId': activeMethodId,
              'calleeId': 'workspace://$filePath#$instance.$method',
              'type': CallType.normal
            });
          }
        }

        for (final match in superCallRegex.allMatches(line)) {
          final method = match.group(1)!;
          calls.add({
            'callerId': activeMethodId,
            'calleeId': 'workspace://$filePath#super.$method',
            'type': CallType.superCall
          });
        }

        for (final match in constructorRegex.allMatches(line)) {
          final cls = match.group(1)!;
          calls.add({
            'callerId': activeMethodId,
            'calleeId': 'workspace://$filePath#$cls',
            'type': CallType.constructor
          });
        }
      }
    }

    final completedSymbols = symbols.map((sym) {
      if (sym.kind == SymbolKind.classSymbol) {
        return sym.copyWith(childrenIds: parentChildrenMap[sym.id] ?? []);
      }
      return sym;
    }).toList();

    return WorkspaceParseResult(
      symbols: completedSymbols,
      imports: imports,
      calls: calls,
      diagnostics: diagnostics,
    );
  }
}
