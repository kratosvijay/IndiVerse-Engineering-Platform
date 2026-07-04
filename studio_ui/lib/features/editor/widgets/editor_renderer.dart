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
  final List<Position> bracketMatches;

  PaintContext({
    required this.snapshot,
    required this.viewport,
    required this.theme,
    required this.gutters,
    required this.decorations,
    required this.controller,
    this.bracketMatches = const [],
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
  double getWidth(PaintContext context) => 52.0;

  @override
  void paint(PaintContext context, Canvas canvas, Rect bounds) {
    final paint = Paint()..color = context.theme.gutterBackgroundColor;
    canvas.drawRect(bounds, paint);

    final textStyle = context.theme.textStyle.copyWith(
      color: context.theme.gutterForegroundColor,
    );

    final double lineHeight = 20.0;
    final int visualLineCount = context.controller.visualLineCount;
    final double scrollOffset = context.viewport.verticalOffset;
    final double viewportHeight = context.viewport.viewportHeight;

    if (visualLineCount == 0) return;

    final int firstVisualIdx = (scrollOffset / lineHeight).floor().clamp(
      0,
      visualLineCount - 1,
    );
    final int lastVisualIdx = ((scrollOffset + viewportHeight) / lineHeight)
        .ceil()
        .clamp(0, visualLineCount - 1);

    for (int idx = firstVisualIdx; idx <= lastVisualIdx; idx++) {
      final actualLine = context.controller.visualToActualLine(idx);
      final textPainter = TextPainter(
        text: TextSpan(text: '$actualLine', style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      final y = idx * lineHeight - scrollOffset;
      final x = bounds.width - textPainter.width - 16.0;
      textPainter.paint(canvas, Offset(bounds.left + x, bounds.top + y));

      final region = context.controller.document.foldingLookup[actualLine];
      if (region != null) {
        final icon = region.collapsed ? '▶' : '▼';
        final iconStyle = textStyle.copyWith(
          color: const Color(0xFFA78BFA),
          fontSize: 8.0,
          fontWeight: FontWeight.bold,
        );
        final iconPainter = TextPainter(
          text: TextSpan(text: icon, style: iconStyle),
          textDirection: TextDirection.ltr,
        )..layout();
        iconPainter.paint(
          canvas,
          Offset(bounds.left + bounds.width - 12.0, bounds.top + y + 6.0),
        );
      }
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

    final int activeLine = context.controller.document.cursorLine;
    final int activeVisualIdx = context.controller.actualToVisualLine(
      activeLine,
    );
    final isCursorVisible =
        context.controller.visualToActualLine(activeVisualIdx) == activeLine;

    // Active line background highlight
    if (isCursorVisible) {
      final activeLinePaint = Paint()
        ..color = context.theme.activeLineBackgroundColor;
      final double y =
          activeVisualIdx * lineHeight - context.viewport.verticalOffset;
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
        final visualIdx = context.controller.actualToVisualLine(line);
        final isLineVisible =
            context.controller.visualToActualLine(visualIdx) == line;
        if (isLineVisible) {
          final double y =
              visualIdx * lineHeight - context.viewport.verticalOffset;
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
    final int visualLineCount = context.controller.visualLineCount;
    if (visualLineCount > 0) {
      final int firstVisualIdx = (context.viewport.verticalOffset / lineHeight)
          .floor()
          .clamp(0, visualLineCount - 1);
      final int lastVisualIdx =
          ((context.viewport.verticalOffset + size.height) / lineHeight)
              .ceil()
              .clamp(0, visualLineCount - 1);

      for (int idx = firstVisualIdx; idx <= lastVisualIdx; idx++) {
        final actualLine = context.controller.visualToActualLine(idx);
        final double y = idx * lineHeight - context.viewport.verticalOffset;

        final tokensSpan = context.controller.getLineTokens(
          buildContext,
          actualLine,
        );
        final textPainter = TextPainter(
          text: tokensSpan,
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(
          canvas,
          Offset(
            gutterWidth + 12.0 - context.viewport.horizontalOffset,
            y + 2.0,
          ),
        );

        final region = context.controller.document.foldingLookup[actualLine];
        if (region != null && region.collapsed) {
          final double placeholderX =
              gutterWidth +
              12.0 +
              textPainter.width -
              context.viewport.horizontalOffset;
          final placeholderPainter = TextPainter(
            text: const TextSpan(
              text: ' ... ',
              style: TextStyle(
                color: Color(0xFFA78BFA),
                backgroundColor: Color(0xFF2C1C4D),
                fontWeight: FontWeight.bold,
                fontSize: 10.0,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          placeholderPainter.paint(canvas, Offset(placeholderX + 6.0, y + 2.0));
        }
      }
    }

    // 3. Decorations Layer (Diagnostics, etc.)
    for (final decoration in context.decorations) {
      decoration.paint(
        context,
        canvas,
        Rect.fromLTWH(gutterWidth, 0, size.width - gutterWidth, size.height),
      );
    }

    // 4. Cursor Layer
    final cursor = context.controller.document.cursor;
    final int cursorVisualIdx = context.controller.actualToVisualLine(
      cursor.line,
    );
    final isCursorLineVisible =
        context.controller.visualToActualLine(cursorVisualIdx) == cursor.line;

    if (isCursorLineVisible) {
      final double y =
          cursorVisualIdx * lineHeight - context.viewport.verticalOffset;
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

    // Bracket highlights
    for (final pos in context.bracketMatches) {
      final visualIdx = context.controller.actualToVisualLine(pos.line);
      final isLineVisible =
          context.controller.visualToActualLine(visualIdx) == pos.line;
      if (isLineVisible) {
        final double y =
            visualIdx * lineHeight - context.viewport.verticalOffset;
        final lineText = context.snapshot.lines[pos.line - 1];
        final col = pos.column.clamp(1, lineText.length + 1);
        final textBefore = lineText.substring(0, col - 1);
        final textPainter = TextPainter(
          text: TextSpan(text: textBefore, style: context.theme.textStyle),
          textDirection: TextDirection.ltr,
        )..layout();

        final double charX =
            gutterWidth +
            12.0 +
            textPainter.width -
            context.viewport.horizontalOffset;
        final borderPaint = Paint()
          ..color = context.theme.bracketMatchColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
        canvas.drawRect(
          Rect.fromLTWH(charX, y + 2.0, 8.0, lineHeight - 4.0),
          borderPaint,
        );
      }
    }

    // 5. Overlay Layer (gutters)
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
  }

  @override
  bool shouldRepaint(covariant EditorRenderer oldDelegate) {
    return oldDelegate.context.snapshot.revision != context.snapshot.revision ||
        oldDelegate.context.viewport != context.viewport ||
        oldDelegate.context.controller.document.cursor !=
            context.controller.document.cursor;
  }
}
