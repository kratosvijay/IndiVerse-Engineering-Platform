import 'package:flutter/material.dart';
import '../widgets/editor_renderer.dart';
import '../../../core/state/studio_state.dart';
import '../../../models/language_intelligence_models.dart';

class DiagnosticsGutterProvider implements GutterProvider {
  final StudioState state;

  DiagnosticsGutterProvider(this.state);

  @override
  double getWidth(PaintContext context) => 16.0;

  @override
  void paint(PaintContext context, Canvas canvas, Rect bounds) {
    final double lineHeight = 20.0;
    final double scrollOffset = context.viewport.verticalOffset;
    final double viewportHeight = context.viewport.viewportHeight;

    final doc = context.controller.document;
    final diags = state.diagnostics.getForFile(doc.path);
    if (diags.isEmpty) return;

    final visualLineCount = context.controller.visualLineCount;
    if (visualLineCount == 0) return;

    final int firstVisualIdx = (scrollOffset / lineHeight).floor().clamp(
      0,
      visualLineCount - 1,
    );
    final int lastVisualIdx = ((scrollOffset + viewportHeight) / lineHeight)
        .ceil()
        .clamp(0, visualLineCount - 1);

    final lineSeverities = <int, DiagnosticSeverity>{};
    for (final diag in diags) {
      final line = diag.range.start.line;
      final existing = lineSeverities[line];
      if (existing == null || diag.severity.index < existing.index) {
        lineSeverities[line] = diag.severity;
      }
    }

    for (int idx = firstVisualIdx; idx <= lastVisualIdx; idx++) {
      final actualLine = context.controller.visualToActualLine(idx);
      final severity = lineSeverities[actualLine];
      if (severity == null) continue;

      final double y = idx * lineHeight - scrollOffset;
      final double centerX = bounds.left + bounds.width / 2;
      final double centerY = bounds.top + y + lineHeight / 2;

      _drawGutterIcon(canvas, severity, centerX, centerY);
    }
  }

  void _drawGutterIcon(
    Canvas canvas,
    DiagnosticSeverity severity,
    double cx,
    double cy,
  ) {
    switch (severity) {
      case DiagnosticSeverity.error:
        final paint = Paint()..color = Colors.redAccent;
        canvas.drawCircle(Offset(cx, cy), 4.0, paint);
        break;
      case DiagnosticSeverity.warning:
        final paint = Paint()
          ..color = Colors.orangeAccent
          ..style = PaintingStyle.fill;
        final path = Path()
          ..moveTo(cx, cy - 4.5)
          ..lineTo(cx - 4.5, cy + 3.5)
          ..lineTo(cx + 4.5, cy + 3.5)
          ..close();
        canvas.drawPath(path, paint);
        break;
      case DiagnosticSeverity.information:
        final paint = Paint()..color = Colors.blueAccent;
        canvas.drawCircle(Offset(cx, cy), 4.0, paint);
        break;
      case DiagnosticSeverity.hint:
        final paint = Paint()..color = Colors.grey;
        final path = Path()
          ..moveTo(cx, cy - 4.0)
          ..lineTo(cx - 4.0, cy)
          ..lineTo(cx, cy + 4.0)
          ..lineTo(cx + 4.0, cy)
          ..close();
        canvas.drawPath(path, paint);
        break;
    }
  }
}
