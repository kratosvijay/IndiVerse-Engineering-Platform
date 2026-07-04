import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../models/editor_document.dart';
import '../../../models/language_intelligence_models.dart';
import '../widgets/editor_renderer.dart';
import '../controllers/editor_view_controller.dart';
import '../../../core/state/studio_state.dart';

class DiagnosticsDecorationProvider implements DecorationProvider {
  final StudioState state;

  DiagnosticsDecorationProvider(this.state);

  @override
  void paint(PaintContext context, Canvas canvas, Rect bounds) {
    final double lineHeight = 20.0;
    double gutterWidth = 0.0;
    for (final gutter in context.gutters) {
      gutterWidth += gutter.getWidth(context);
    }

    final doc = context.controller.document;
    final diags = state.diagnostics.getForFile(doc.path);
    if (diags.isEmpty) return;

    final visualLineCount = context.controller.visualLineCount;
    if (visualLineCount == 0) return;

    final double verticalOffset = context.viewport.verticalOffset;
    final double horizontalOffset = context.viewport.horizontalOffset;

    final int firstVisualIdx = (verticalOffset / lineHeight).floor().clamp(
      0,
      visualLineCount - 1,
    );
    final int lastVisualIdx = ((verticalOffset + bounds.height) / lineHeight)
        .ceil()
        .clamp(0, visualLineCount - 1);

    for (final diag in diags) {
      final sLine = diag.range.start.line;
      final eLine = diag.range.end.line;

      for (int line = sLine; line <= eLine; line++) {
        final visualIdx = context.controller.actualToVisualLine(line);
        if (visualIdx < firstVisualIdx || visualIdx > lastVisualIdx) continue;

        final isLineVisible =
            context.controller.visualToActualLine(visualIdx) == line;
        if (!isLineVisible) continue;

        final lineText = line <= context.snapshot.lines.length
            ? context.snapshot.lines[line - 1]
            : '';

        int colStart = 1;
        int colEnd = lineText.length + 1;

        if (line == sLine) {
          colStart = diag.range.start.column.clamp(1, lineText.length + 1);
        }
        if (line == eLine) {
          colEnd = diag.range.end.column.clamp(1, lineText.length + 1);
        }
        if (colEnd <= colStart) {
          colEnd = colStart + 1;
        }

        final textBefore = lineText.substring(0, colStart - 1);
        final beforePainter = TextPainter(
          text: TextSpan(text: textBefore, style: context.theme.textStyle),
          textDirection: TextDirection.ltr,
        )..layout();

        final targetText = lineText.substring(
          colStart - 1,
          (colEnd - 1).clamp(0, lineText.length),
        );
        final targetPainter = TextPainter(
          text: TextSpan(text: targetText, style: context.theme.textStyle),
          textDirection: TextDirection.ltr,
        )..layout();

        final double xStart =
            gutterWidth + 12.0 + beforePainter.width - horizontalOffset;
        final double xEnd = xStart + targetPainter.width;
        final double y = visualIdx * lineHeight - verticalOffset;

        _drawDiagnosticDecorations(
          canvas,
          context,
          diag,
          xStart,
          xEnd,
          y,
          lineHeight,
        );
      }
    }
  }

  void _drawDiagnosticDecorations(
    Canvas canvas,
    PaintContext context,
    Diagnostic diag,
    double xStart,
    double xEnd,
    double y,
    double lineHeight,
  ) {
    if (diag.tags.contains(DiagnosticTag.unnecessary)) {
      final fadePaint = Paint()
        ..color = context.theme.backgroundColor.withOpacity(0.5)
        ..style = PaintingStyle.fill;
      canvas.drawRect(
        Rect.fromLTWH(xStart, y + 2.0, xEnd - xStart, lineHeight - 4.0),
        fadePaint,
      );
    }

    if (diag.tags.contains(DiagnosticTag.deprecated)) {
      final strikePaint = Paint()
        ..color = Colors.grey
        ..strokeWidth = 1.0;
      canvas.drawLine(
        Offset(xStart, y + lineHeight / 2 + 1.0),
        Offset(xEnd, y + lineHeight / 2 + 1.0),
        strikePaint,
      );
    }

    Color squiggleColor;
    bool isDotted = false;
    switch (diag.severity) {
      case DiagnosticSeverity.error:
        squiggleColor = Colors.redAccent;
        break;
      case DiagnosticSeverity.warning:
        squiggleColor = Colors.orangeAccent;
        break;
      case DiagnosticSeverity.information:
        squiggleColor = Colors.blueAccent;
        break;
      case DiagnosticSeverity.hint:
        squiggleColor = Colors.grey;
        isDotted = true;
        break;
    }

    final double squiggleY = y + lineHeight - 2.0;
    if (isDotted) {
      final dotPaint = Paint()
        ..color = squiggleColor
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;
      for (double x = xStart; x < xEnd; x += 3.0) {
        canvas.drawPoints(PointMode.points, [Offset(x, squiggleY)], dotPaint);
      }
    } else {
      final path = Path();
      double currentX = xStart;
      path.moveTo(currentX, squiggleY);
      bool up = true;
      while (currentX < xEnd) {
        currentX += 2.0;
        path.lineTo(currentX, squiggleY + (up ? -2.0 : 2.0));
        up = !up;
      }
      final paint = Paint()
        ..color = squiggleColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawPath(path, paint);
    }
  }
}
