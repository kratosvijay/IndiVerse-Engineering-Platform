import 'package:flutter/material.dart';
import 'abstract_highlighter.dart';
import 'theme.dart';

class JsonHighlighter extends SyntaxHighlighter {
  @override
  InlineSpan highlight(BuildContext context, String source) {
    final spans = <TextSpan>[];
    final lines = source.split('\n');
    
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final parts = line.split(':');
      
      if (parts.length > 1) {
        final keyPart = parts[0];
        final valPart = line.substring(keyPart.length + 1);
        
        spans.add(TextSpan(text: keyPart, style: const TextStyle(color: SyntaxTheme.type, fontWeight: FontWeight.bold)));
        spans.add(const TextSpan(text: ':', style: TextStyle(color: SyntaxTheme.normal)));
        
        final words = valPart.split(RegExp(r'(\s+|[{},[\]])'));
        var currentPos = 0;
        
        for (final word in words) {
          if (word.isEmpty) continue;
          final startIdx = valPart.indexOf(word, currentPos);
          if (startIdx > currentPos) {
            spans.add(TextSpan(text: valPart.substring(currentPos, startIdx), style: const TextStyle(color: SyntaxTheme.normal)));
          }
          
          TextStyle style;
          if (word.startsWith('"') || word.endsWith('"')) {
            style = const TextStyle(color: SyntaxTheme.string);
          } else if (RegExp(r'^[0-9]+$').hasMatch(word)) {
            style = const TextStyle(color: SyntaxTheme.number);
          } else if (word == 'true' || word == 'false') {
            style = const TextStyle(color: SyntaxTheme.keyword);
          } else {
            style = const TextStyle(color: SyntaxTheme.normal);
          }
          
          spans.add(TextSpan(text: word, style: style));
          currentPos = startIdx + word.length;
        }
        if (currentPos < valPart.length) {
          spans.add(TextSpan(text: valPart.substring(currentPos), style: const TextStyle(color: SyntaxTheme.normal)));
        }
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
