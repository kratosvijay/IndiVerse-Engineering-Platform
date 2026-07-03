import 'package:flutter/material.dart';
import 'abstract_highlighter.dart';
import 'theme.dart';

class MarkdownHighlighter extends SyntaxHighlighter {
  @override
  InlineSpan highlight(BuildContext context, String source) {
    final spans = <TextSpan>[];
    final lines = source.split('\n');
    
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trim();
      
      if (trimmed.startsWith('#')) {
        spans.add(TextSpan(text: line, style: const TextStyle(color: SyntaxTheme.keyword, fontWeight: FontWeight.bold, fontSize: 14)));
      } else if (trimmed.startsWith('-') || trimmed.startsWith('*')) {
        spans.add(TextSpan(text: line, style: const TextStyle(color: SyntaxTheme.type)));
      } else if (trimmed.startsWith('>')) {
        spans.add(TextSpan(text: line, style: const TextStyle(color: SyntaxTheme.comment, fontStyle: FontStyle.italic)));
      } else {
        spans.add(TextSpan(text: line, style: const TextStyle(color: SyntaxTheme.normal)));
      }
      
      if (i < lines.length - 1) {
        spans.add(const TextSpan(text: '\n'));
      }
    }
    
    return TextSpan(children: spans);
  }
}
