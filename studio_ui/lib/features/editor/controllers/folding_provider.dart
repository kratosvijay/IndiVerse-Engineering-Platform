import '../../../models/editor_document.dart';
import '../../../models/folding_region.dart';

abstract class FoldingProvider {
  List<FoldingRegion> build(EditorDocument document);
}

class BracketFoldingProvider implements FoldingProvider {
  @override
  List<FoldingRegion> build(EditorDocument document) {
    final regions = <FoldingRegion>[];

    final braceStack = <Map<String, dynamic>>[];
    final bracketStack = <Map<String, dynamic>>[];
    final parenStack = <Map<String, dynamic>>[];

    for (int i = 0; i < document.lineCount; i++) {
      final line = document.lines[i];
      final lineNum = i + 1;

      for (int c = 0; c < line.length; c++) {
        final char = line[c];
        final colNum = c + 1;

        if (char == '{') {
          braceStack.add({'line': lineNum, 'col': colNum});
        } else if (char == '}') {
          if (braceStack.isNotEmpty) {
            final start = braceStack.removeLast();
            if (start['line'] != lineNum) {
              final startLine = start['line'] as int;
              final signature = _generateSignature(
                document,
                startLine,
                lineNum,
              );
              regions.add(
                FoldingRegion(
                  startLine: startLine,
                  endLine: lineNum,
                  signature: signature,
                ),
              );
            }
          }
        } else if (char == '[') {
          bracketStack.add({'line': lineNum, 'col': colNum});
        } else if (char == ']') {
          if (bracketStack.isNotEmpty) {
            final start = bracketStack.removeLast();
            if (start['line'] != lineNum) {
              final startLine = start['line'] as int;
              final signature = _generateSignature(
                document,
                startLine,
                lineNum,
              );
              regions.add(
                FoldingRegion(
                  startLine: startLine,
                  endLine: lineNum,
                  signature: signature,
                ),
              );
            }
          }
        } else if (char == '(') {
          parenStack.add({'line': lineNum, 'col': colNum});
        } else if (char == ')') {
          if (parenStack.isNotEmpty) {
            final start = parenStack.removeLast();
            if (start['line'] != lineNum) {
              final startLine = start['line'] as int;
              final signature = _generateSignature(
                document,
                startLine,
                lineNum,
              );
              regions.add(
                FoldingRegion(
                  startLine: startLine,
                  endLine: lineNum,
                  signature: signature,
                ),
              );
            }
          }
        }
      }
    }

    regions.sort((a, b) {
      final cmp = a.startLine.compareTo(b.startLine);
      if (cmp != 0) return cmp;
      return b.endLine.compareTo(a.endLine);
    });

    return _buildTree(regions);
  }

  String _generateSignature(EditorDocument doc, int startLine, int endLine) {
    final startText = doc.lines[startLine - 1].trim();
    final len = startText.length.clamp(0, 30);
    final textPrefix = startText.substring(0, len);
    return '$textPrefix@${endLine - startLine}';
  }

  List<FoldingRegion> _buildTree(List<FoldingRegion> flatRegions) {
    final roots = <FoldingRegion>[];
    for (final region in flatRegions) {
      if (!_insertIntoTree(roots, region)) {
        roots.add(region);
      }
    }
    return roots;
  }

  bool _insertIntoTree(List<FoldingRegion> parents, FoldingRegion child) {
    for (int i = parents.length - 1; i >= 0; i--) {
      final parent = parents[i];
      if (parent.startLine <= child.startLine &&
          parent.endLine >= child.endLine) {
        final List<FoldingRegion> updatedChildren = List.from(parent.children);
        if (!_insertIntoTree(updatedChildren, child)) {
          updatedChildren.add(child);
          updatedChildren.sort((a, b) => a.startLine.compareTo(b.startLine));
        }
        parents[i] = parent.copyWith(children: updatedChildren);
        return true;
      }
    }
    return false;
  }
}

class DartFoldingProvider extends BracketFoldingProvider {}

class JsonFoldingProvider extends BracketFoldingProvider {}

class YamlFoldingProvider extends BracketFoldingProvider {}

class MarkdownFoldingProvider implements FoldingProvider {
  @override
  List<FoldingRegion> build(EditorDocument document) {
    final regions = <FoldingRegion>[];
    final headerStack = <Map<String, int>>[];

    for (int i = 0; i < document.lineCount; i++) {
      final line = document.lines[i];
      final lineNum = i + 1;

      if (line.startsWith('#')) {
        final level = line.indexOf(RegExp(r'[^#]'));
        if (level > 0) {
          while (headerStack.isNotEmpty &&
              headerStack.last['level']! >= level) {
            final start = headerStack.removeLast();
            final startLine = start['line']!;
            if (startLine < lineNum - 1) {
              regions.add(
                FoldingRegion(
                  startLine: startLine,
                  endLine: lineNum - 1,
                  signature: 'md-h${start['level']}@${lineNum - 1 - startLine}',
                ),
              );
            }
          }
          headerStack.add({'line': lineNum, 'level': level});
        }
      }
    }

    while (headerStack.isNotEmpty) {
      final start = headerStack.removeLast();
      final startLine = start['line']!;
      if (startLine < document.lineCount) {
        regions.add(
          FoldingRegion(
            startLine: startLine,
            endLine: document.lineCount,
            signature:
                'md-h${start['level']}@${document.lineCount - startLine}',
          ),
        );
      }
    }

    regions.sort((a, b) => a.startLine.compareTo(b.startLine));
    return _buildTree(regions);
  }

  List<FoldingRegion> _buildTree(List<FoldingRegion> flatRegions) {
    final roots = <FoldingRegion>[];
    for (final region in flatRegions) {
      if (!_insertIntoTree(roots, region)) {
        roots.add(region);
      }
    }
    return roots;
  }

  bool _insertIntoTree(List<FoldingRegion> parents, FoldingRegion child) {
    for (int i = parents.length - 1; i >= 0; i--) {
      final parent = parents[i];
      if (parent.startLine <= child.startLine &&
          parent.endLine >= child.endLine) {
        final List<FoldingRegion> updatedChildren = List.from(parent.children);
        if (!_insertIntoTree(updatedChildren, child)) {
          updatedChildren.add(child);
          updatedChildren.sort((a, b) => a.startLine.compareTo(b.startLine));
        }
        parents[i] = parent.copyWith(children: updatedChildren);
        return true;
      }
    }
    return false;
  }
}
