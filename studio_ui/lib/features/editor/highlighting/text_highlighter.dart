import 'package:flutter/material.dart';
import 'abstract_highlighter.dart';
import 'theme.dart';

class TextHighlighter extends SyntaxHighlighter {
  @override
  InlineSpan highlight(BuildContext context, String source) {
    return TextSpan(text: source, style: const TextStyle(color: SyntaxTheme.normal));
  }
}
