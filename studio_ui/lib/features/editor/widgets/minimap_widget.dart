import 'package:flutter/material.dart';
import '../../../models/minimap_snapshot.dart';
import '../controllers/editor_view_controller.dart';

class MinimapWidget extends StatelessWidget {
  final EditorViewController viewController;
  final ScrollController scrollController;

  const MinimapWidget({
    super.key,
    required this.viewController,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final doc = viewController.document;
    final viewport = viewController.viewport;

    final snapshot = MinimapSnapshot(
      lines: doc.lines,
      firstVisibleLine: viewport.firstVisibleLine,
      lastVisibleLine: viewport.lastVisibleLine,
      foldedRegions: doc.foldingRegions,
    );

    return GestureDetector(
      onTapDown: (details) => _handleScroll(context, details.localPosition.dy),
      onVerticalDragUpdate: (details) =>
          _handleScroll(context, details.localPosition.dy),
      child: Container(
        width: 80,
        color: const Color(0xFF131024),
        child: CustomPaint(
          painter: MinimapPainter(
            snapshot: snapshot,
            viewController: viewController,
          ),
        ),
      ),
    );
  }

  void _handleScroll(BuildContext context, double localY) {
    if (!scrollController.hasClients) return;

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final totalHeight = renderBox.size.height;

    final maxScroll = scrollController.position.maxScrollExtent;
    final double scrollPercent = (localY / totalHeight).clamp(0.0, 1.0);

    scrollController.jumpTo(scrollPercent * maxScroll);
  }
}

class MinimapPainter extends CustomPainter {
  final MinimapSnapshot snapshot;
  final EditorViewController viewController;

  MinimapPainter({required this.snapshot, required this.viewController});

  @override
  void paint(Canvas canvas, Size size) {
    if (snapshot.lines.isEmpty) return;

    final double minimapHeight = size.height;
    final double minimapWidth = size.width;

    final bgPaint = Paint()..color = const Color(0xFF131024);
    canvas.drawRect(Rect.fromLTWH(0, 0, minimapWidth, minimapHeight), bgPaint);

    final double docLineCount = snapshot.lines.length.toDouble();
    final double rawLineHeight = minimapHeight / docLineCount;
    final double lineHeight = rawLineHeight.clamp(1.0, 3.0);

    final linePaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = lineHeight - 0.2;

    final foldedPaint = Paint()
      ..color = const Color(0xFF4C1D95)
      ..strokeWidth = lineHeight;

    final visualLineCount = viewController.visualLineCount;
    for (int idx = 0; idx < visualLineCount; idx++) {
      final actualLine = viewController.visualToActualLine(idx);
      if (actualLine > snapshot.lines.length) continue;

      final lineText = snapshot.lines[actualLine - 1];
      final double y = idx * lineHeight;
      if (y > minimapHeight) break;

      final leadingSpaces = lineText.length - lineText.trimLeft().length;
      final double startX = (leadingSpaces * 1.5).clamp(
        0.0,
        minimapWidth - 10.0,
      );
      final double lineLen = (lineText.trim().length * 0.8).clamp(
        2.0,
        minimapWidth - startX - 4.0,
      );

      final region = viewController.document.foldingLookup[actualLine];
      if (region != null && region.collapsed) {
        canvas.drawLine(
          Offset(startX, y),
          Offset(startX + 12.0, y),
          foldedPaint,
        );
      } else {
        canvas.drawLine(
          Offset(startX, y),
          Offset(startX + lineLen, y),
          linePaint,
        );
      }
    }

    final int firstVisual = viewController.actualToVisualLine(
      snapshot.firstVisibleLine,
    );
    final int lastVisual = viewController.actualToVisualLine(
      snapshot.lastVisibleLine,
    );
    final double viewTop = firstVisual * lineHeight;
    final double viewBottom = (lastVisual + 1) * lineHeight;

    final viewportPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final viewportRect = Rect.fromLTRB(
      0.0,
      viewTop,
      minimapWidth,
      viewBottom.clamp(0.0, minimapHeight),
    );
    canvas.drawRect(viewportRect, viewportPaint);
    canvas.drawRect(viewportRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant MinimapPainter oldDelegate) {
    return oldDelegate.snapshot.firstVisibleLine != snapshot.firstVisibleLine ||
        oldDelegate.snapshot.lastVisibleLine != snapshot.lastVisibleLine ||
        oldDelegate.snapshot.lines.length != snapshot.lines.length;
  }
}
