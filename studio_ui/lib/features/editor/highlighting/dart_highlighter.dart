import 'package:flutter/material.dart';
import 'abstract_highlighter.dart';
import 'theme.dart';

class DartHighlighter extends SyntaxHighlighter {
  static const _keywords = {
    'class',
    'import',
    'void',
    'final',
    'const',
    'return',
    'async',
    'await',
    'if',
    'else',
    'for',
    'in',
    'while',
    'switch',
    'case',
    'break',
    'continue',
    'late',
    'var',
    'get',
    'set',
    'extends',
    'implements',
    'with',
    'override',
    'static',
    'factory',
    'dynamic',
    'int',
    'double',
    'num',
    'bool',
    'String',
    'List',
    'Map',
    'Set',
    'Future',
    'Stream',
    'ChangeNotifier',
    'Widget',
    'BuildContext',
  };

  @override
  InlineSpan highlight(BuildContext context, String source) {
    final spans = <TextSpan>[];
    final lines = source.split('\n');

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.trim().startsWith('//')) {
        spans.add(
          TextSpan(
            text: line,
            style: const TextStyle(color: SyntaxTheme.comment),
          ),
        );
      } else {
        final words = line.split(RegExp(r'(\s+|[(){}[\].,;?:+\-*\/&|=!<>])'));
        var currentPos = 0;

        for (final word in words) {
          if (word.isEmpty) continue;

          final startIdx = line.indexOf(word, currentPos);
          if (startIdx > currentPos) {
            final gap = line.substring(currentPos, startIdx);
            spans.add(
              TextSpan(
                text: gap,
                style: const TextStyle(color: SyntaxTheme.normal),
              ),
            );
          }

          TextStyle style;
          if (_keywords.contains(word)) {
            style = const TextStyle(
              color: SyntaxTheme.keyword,
              fontWeight: FontWeight.bold,
            );
          } else if (word.startsWith('@')) {
            style = const TextStyle(color: SyntaxTheme.annotation);
          } else if (word.startsWith('"') ||
              word.startsWith("'") ||
              word.endsWith('"') ||
              word.endsWith("'")) {
            style = const TextStyle(color: SyntaxTheme.string);
          } else if (RegExp(r'^[0-9]+$').hasMatch(word)) {
            style = const TextStyle(color: SyntaxTheme.number);
          } else if (RegExp(r'^[A-Z][A-Za-z0-9_]*$').hasMatch(word)) {
            style = const TextStyle(color: SyntaxTheme.type);
          } else {
            style = const TextStyle(color: SyntaxTheme.normal);
          }

          spans.add(TextSpan(text: word, style: style));
          currentPos = startIdx + word.length;
        }

        if (currentPos < line.length) {
          spans.add(
            TextSpan(
              text: line.substring(currentPos),
              style: const TextStyle(color: SyntaxTheme.normal),
            ),
          );
        }
      }

      if (i < lines.length - 1) {
        spans.add(const TextSpan(text: '\n'));
      }
    }

    return TextSpan(children: spans);
  }
}
