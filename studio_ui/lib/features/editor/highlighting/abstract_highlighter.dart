import 'package:flutter/widgets.dart';

abstract class SyntaxHighlighter {
  InlineSpan highlight(BuildContext context, String source);
}
