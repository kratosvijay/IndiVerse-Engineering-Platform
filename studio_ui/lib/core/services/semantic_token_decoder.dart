import '../../models/semantic_token.dart';
import '../../models/editor_document.dart';

class SemanticTokenDecoder {
  static List<SemanticToken> decode(List<int> rawData) {
    final List<SemanticToken> tokens = [];
    int currentLine = 1;
    int currentColumn = 1;

    for (int i = 0; i < rawData.length; i += 5) {
      if (i + 4 >= rawData.length) break;

      final deltaLine = rawData[i];
      final deltaStart = rawData[i + 1];
      final length = rawData[i + 2];
      final typeIndex = rawData[i + 3];
      final modifierBitmask = rawData[i + 4];

      if (deltaLine > 0) {
        currentLine += deltaLine;
        currentColumn = deltaStart + 1; // 1-based index
      } else {
        currentColumn += deltaStart;
      }

      SemanticTokenType tokenType;
      if (typeIndex >= 0 && typeIndex < SemanticTokenType.values.length) {
        tokenType = SemanticTokenType.values[typeIndex];
      } else {
        tokenType = SemanticTokenType.variable;
      }

      final Set<SemanticTokenModifier> modifiers = {};
      for (int m = 0; m < SemanticTokenModifier.values.length; m++) {
        if ((modifierBitmask & (1 << m)) != 0) {
          modifiers.add(SemanticTokenModifier.values[m]);
        }
      }

      tokens.add(
        SemanticToken(
          start: Position(line: currentLine, column: currentColumn),
          length: length,
          type: tokenType,
          modifiers: modifiers,
        ),
      );
    }
    return tokens;
  }
}

class SemanticTokenValidator {
  static bool isValid(
    SemanticToken token,
    int totalLines,
    List<String> documentLines,
  ) {
    if (token.start.line < 1 || token.start.line > totalLines) return false;
    if (token.start.column < 1) return false;
    if (token.length <= 0) return false;

    final lineText = documentLines[token.start.line - 1];
    if (token.start.column > lineText.length + 1) return false;

    return true;
  }

  static List<SemanticToken> validateAll(
    List<SemanticToken> tokens,
    List<String> documentLines,
  ) {
    return tokens
        .where((t) => isValid(t, documentLines.length, documentLines))
        .toList();
  }
}

class SemanticTokenNormalizer {
  static List<SemanticToken> normalize(List<SemanticToken> tokens) {
    if (tokens.isEmpty) return [];

    final List<SemanticToken> sorted = List.from(tokens);
    sorted.sort((a, b) {
      final lineComp = a.start.line.compareTo(b.start.line);
      if (lineComp != 0) return lineComp;
      final colComp = a.start.column.compareTo(b.start.column);
      if (colComp != 0) return colComp;
      return b.length.compareTo(a.length);
    });

    final List<SemanticToken> normalized = [];
    for (final token in sorted) {
      if (normalized.isEmpty) {
        normalized.add(token);
        continue;
      }

      final last = normalized.last;
      if (last.start.line == token.start.line &&
          last.start.column == token.start.column) {
        if (last.length == token.length) {
          final mergedModifiers = Set<SemanticTokenModifier>.from(
            last.modifiers,
          )..addAll(token.modifiers);
          normalized[normalized.length - 1] = SemanticToken(
            start: last.start,
            length: last.length,
            type: last.type,
            modifiers: mergedModifiers,
          );
        }
        continue;
      }

      if (last.start.line == token.start.line) {
        final lastEnd = last.start.column + last.length;
        if (token.start.column < lastEnd) {
          continue;
        }
      }

      normalized.add(token);
    }

    return normalized;
  }
}
