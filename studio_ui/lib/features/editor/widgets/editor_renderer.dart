import 'package:flutter/material.dart';
import '../../../models/editor_document.dart';
import '../controllers/editor_view_controller.dart';

class EditorTheme {
  final Color backgroundColor;
  final Color foregroundColor;
  final Color gutterBackgroundColor;
  final Color gutterForegroundColor;
  final Color activeLineBackgroundColor;
  final Color selectionColor;
  final Color caretColor;
  final Color bracketMatchColor;
  final TextStyle textStyle;

  const EditorTheme({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.gutterBackgroundColor,
    required this.gutterForegroundColor,
    required this.activeLineBackgroundColor,
    required this.selectionColor,
    required this.caretColor,
    required this.bracketMatchColor,
    required this.textStyle,
  });

  static const defaultDark = EditorTheme(
    backgroundColor: Color(0xFF0F0C1B),
    foregroundColor: Colors.white,
    gutterBackgroundColor: Color(0xFF131024),
    gutterForegroundColor: Colors.white24,
    activeLineBackgroundColor: Color(0xFF2C1C4D),
    selectionColor: Color(0xFF2C284D),
    caretColor: Color(0xFFA78BFA),
    bracketMatchColor: Color(0xFF4C1D95),
    textStyle: TextStyle(
      fontFamily: 'monospace',
      fontSize: 12,
      color: Colors.white,
      height: 1.5,
    ),
  );
}

class PaintContext {
  final DocumentSnapshot snapshot;
  final EditorViewport viewport;
  final EditorTheme theme;
  final List<GutterProvider> gutters;
  final List<DecorationProvider> decorations;
  final EditorViewController controller;

  PaintContext({
    required this.snapshot,
    required this.viewport,
    required this.theme,
    required this.gutters,
    required this.decorations,
    required this.controller,
  });
}

abstract class GutterProvider {
  double getWidth(PaintContext context);
  void paint(PaintContext context, Canvas canvas, Rect bounds);
}

abstract class DecorationProvider {
  void paint(PaintContext context, Canvas canvas, Rect bounds);
}

class LineNumberGutterProvider implements GutterProvider {
  @override
  double getWidth(PaintContext context) => 48.0;

  @override
  void paint(PaintContext context, Canvas canvas, Rect bounds) {
    final paint = Paint()..color = context.theme.gutterBackgroundColor;
    canvas.drawRect(bounds, paint);

    final textStyle = context.theme.textStyle.copyWith(
      color: context.theme.gutterForegroundColor,
    );

    final double lineHeight = 20.0;
    final int startLine = context.viewport.firstVisibleLine;
    final int endLine = context.viewport.lastVisibleLine.clamp(
      1,
      context.snapshot.lines.length,
    );

    for (int line = startLine; line <= endLine; line++) {
      final textPainter = TextPainter(
        text: TextSpan(text: '$line', style: textStyle),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      final y = (line - startLine) * lineHeight;
      final x = bounds.width - textPainter.width - 8.0;
      textPainter.paint(canvas, Offset(bounds.left + x, bounds.top + y));
    }
  }
}

class EditorRenderer extends CustomPainter {
  final PaintContext context;
  final BuildContext buildContext;

  EditorRenderer(this.buildContext, this.context);

  @override
  void paint(Canvas canvas, Size size) {
    final double lineHeight = 20.0;
    double gutterWidth = 0.0;
    for (final gutter in context.gutters) {
      gutterWidth += gutter.getWidth(context);
    }

    // 1. Background Layer
    final bgPaint = Paint()..color = context.theme.backgroundColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Active line background highlight
    final int activeLine = context.controller.document.cursorLine;
    final int startLine = context.viewport.firstVisibleLine;
    if (activeLine >= startLine &&
        activeLine <= context.viewport.lastVisibleLine) {
      final activeLinePaint = Paint()
        ..color = context.theme.activeLineBackgroundColor;
      final double y = (activeLine - startLine) * lineHeight;
      canvas.drawRect(
        Rect.fromLTWH(gutterWidth, y, size.width - gutterWidth, lineHeight),
        activeLinePaint,
      );
    }

    // 2. Selection Layer
    final selection = context.controller.document.selection;
    if (selection != null && !selection.isEmpty) {
      final selectPaint = Paint()..color = context.theme.selectionColor;
      final sLine = selection.start.line;
      final eLine = selection.end.line;
      for (int line = sLine; line <= eLine; line++) {
        if (line >= startLine && line <= context.viewport.lastVisibleLine) {
          final double y = (line - startLine) * lineHeight;
          double xStart = gutterWidth;
          double xEnd = size.width;

          final lineText = line <= context.snapshot.lines.length
              ? context.snapshot.lines[line - 1]
              : '';

          if (line == sLine) {
            final col = selection.start.column.clamp(1, lineText.length + 1);
            final textBefore = lineText.substring(0, col - 1);
            final textPainter = TextPainter(
              text: TextSpan(text: textBefore, style: context.theme.textStyle),
              textDirection: TextDirection.ltr,
            )..layout();
            xStart += textPainter.width + 12.0;
          }
          if (line == eLine) {
            final col = selection.end.column.clamp(1, lineText.length + 1);
            final textBefore = lineText.substring(0, col - 1);
            final textPainter = TextPainter(
              text: TextSpan(text: textBefore, style: context.theme.textStyle),
              textDirection: TextDirection.ltr,
            )..layout();
            xEnd = gutterWidth + textPainter.width + 12.0;
          }
          canvas.drawRect(
            Rect.fromLTWH(xStart, y, xEnd - xStart, lineHeight),
            selectPaint,
          );
        }
      }
    }

    // 3. Syntax/Text Layer
    final int endLine = context.viewport.lastVisibleLine.clamp(
      1,
      context.snapshot.lines.length,
    );
    for (int line = startLine; line <= endLine; line++) {
      final double y = (line - startLine) * lineHeight;
      final tokensSpan = context.controller.getLineTokens(buildContext, line);
      final textPainter = TextPainter(
        text: tokensSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(gutterWidth + 12.0 - context.viewport.horizontalOffset, y + 2.0),
      );
    }

    // 4. Cursor Layer
    final cursor = context.controller.document.cursor;
    if (cursor.line >= startLine &&
        cursor.line <= context.viewport.lastVisibleLine) {
      final double y = (cursor.line - startLine) * lineHeight;
      final lineText = context.snapshot.lines[cursor.line - 1];
      final col = cursor.column.clamp(1, lineText.length + 1);
      final textBefore = lineText.substring(0, col - 1);
      final textPainter = TextPainter(
        text: TextSpan(text: textBefore, style: context.theme.textStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      final double cursorX =
          gutterWidth +
          12.0 +
          textPainter.width -
          context.viewport.horizontalOffset;
      final caretPaint = Paint()
        ..color = context.theme.caretColor
        ..strokeWidth = 2.0;
      canvas.drawLine(
        Offset(cursorX, y + 2.0),
        Offset(cursorX, y + lineHeight - 2.0),
        caretPaint,
      );
    }

    // 5. Overlay Layer (gutters and decorations)
    double currentGutterX = 0.0;
    for (final gutter in context.gutters) {
      final width = gutter.getWidth(context);
      gutter.paint(
        context,
        canvas,
        Rect.fromLTWH(currentGutterX, 0, width, size.height),
      );
      currentGutterX += width;
    }

    for (final decoration in context.decorations) {
      decoration.paint(
        context,
        canvas,
        Rect.fromLTWH(gutterWidth, 0, size.width - gutterWidth, size.height),
      );
    }
  }

  @override
  bool shouldRepaint(covariant EditorRenderer oldDelegate) {
    return oldDelegate.context.snapshot.revision != context.snapshot.revision ||
        oldDelegate.context.viewport != context.viewport ||
        oldDelegate.context.controller.document.cursor !=
            context.controller.document.cursor;
  }
}
