import 'package:flutter/material.dart';
import 'abstract_highlighter.dart';
import 'theme.dart';

class YamlHighlighter extends SyntaxHighlighter {
  @override
  InlineSpan highlight(BuildContext context, String source) {
    final spans = <TextSpan>[];
    final lines = source.split('\n');
    
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.trim().startsWith('#')) {
        spans.add(TextSpan(text: line, style: const TextStyle(color: SyntaxTheme.comment)));
      } else {
        final parts = line.split(':');
        if (parts.length > 1) {
          final keyPart = parts[0];
          final valPart = line.substring(keyPart.length + 1);
          
          spans.add(TextSpan(text: keyPart, style: const TextStyle(color: SyntaxTheme.keyword, fontWeight: FontWeight.bold)));
          spans.add(const TextSpan(text: ':', style: TextStyle(color: SyntaxTheme.normal)));
          
          if (valPart.trim().startsWith('"') || valPart.trim().startsWith("'")) {
            spans.add(TextSpan(text: valPart, style: const TextStyle(color: SyntaxTheme.string)));
          } else {
            spans.add(TextSpan(text: valPart, style: const TextStyle(color: SyntaxTheme.normal)));
          }
        } else {
          spans.add(TextSpan(text: line, style: const TextStyle(color: SyntaxTheme.normal)));
        }
      }
      
      if (i < lines.length - 1) {
        spans.add(const TextSpan(text: '\n'));
      }
    }
    
    return TextSpan(children: spans);
  }
}
