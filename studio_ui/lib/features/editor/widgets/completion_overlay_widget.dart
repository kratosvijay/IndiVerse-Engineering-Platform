import 'package:flutter/material.dart';
import '../../../../models/language_intelligence_models.dart';
import '../../../../models/completion_session.dart';
import '../controllers/completion_controller.dart';

class CompletionOverlayWidget extends StatelessWidget {
  final CompletionSession session;
  final CompletionController controller;
  final double globalX;
  final double globalY;

  const CompletionOverlayWidget({
    super.key,
    required this.session,
    required this.controller,
    required this.globalX,
    required this.globalY,
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screenHeight = media.size.height;
    final screenWidth = media.size.width;

    // Constrain position to fit within viewport edges
    final double overlayWidth = 320.0;
    final double maxOverlayHeight = 260.0;

    double left = globalX;
    double top = globalY;

    if (left + overlayWidth > screenWidth) {
      left = screenWidth - overlayWidth - 16;
    }
    if (left < 16) left = 16;

    if (top + maxOverlayHeight > screenHeight) {
      // Position above the caret if it overflows at the bottom
      top = globalY - maxOverlayHeight - 24;
    }
    if (top < 16) top = 16;

    final selectedItem = session.selectedIndex < session.items.length
        ? session.items[session.selectedIndex]
        : null;

    return Positioned(
      left: left,
      top: top,
      width: overlayWidth,
      child: Material(
        color: Colors.transparent,
        child: Container(
          height: maxOverlayHeight,
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2E),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF3F3F56), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              // 1. Virtualized list view
              Expanded(
                flex: 3,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: session.items.length,
                  itemExtent: 26,
                  itemBuilder: (context, index) {
                    final item = session.items[index];
                    final isSelected = index == session.selectedIndex;

                    return InkWell(
                      onTap: () {
                        session.selectedIndex = index;
                        controller.commitActive();
                      },
                      child: Container(
                        color: isSelected
                            ? const Color(0xFF4C457D)
                            : Colors.transparent,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          children: [
                            // Kind Icon Indicator
                            _buildKindIcon(item.kind),
                            const SizedBox(width: 6),
                            // Label
                            Expanded(
                              child: Text(
                                item.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Courier',
                                  fontSize: 12,
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFFD9E0EE),
                                  decoration: item.deprecated
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            ),
                            if (item.detail != null) ...[
                              const SizedBox(width: 4),
                              Text(
                                item.detail!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 9,
                                  color: isSelected
                                      ? Colors.white70
                                      : const Color(0xFF6C6F85),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // 2. Documentation Preview Pane
              if (selectedItem != null &&
                  (selectedItem.documentation != null ||
                      selectedItem.detail != null)) ...[
                Container(height: 1, color: const Color(0xFF3F3F56)),
                Expanded(
                  flex: 2,
                  child: Container(
                    width: double.infinity,
                    color: const Color(0xFF161622),
                    padding: const EdgeInsets.all(8),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (selectedItem.detail != null)
                            Text(
                              selectedItem.detail!,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF8B5CF6),
                              ),
                            ),
                          if (selectedItem.documentation != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              selectedItem.documentation!,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFFB0B0B0),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKindIcon(CompletionItemKind kind) {
    IconData iconData;
    Color color;

    switch (kind) {
      case CompletionItemKind.method:
      case CompletionItemKind.function:
      case CompletionItemKind.constructor:
        iconData = Icons.functions;
        color = const Color(0xFF89B4FA);
        break;
      case CompletionItemKind.keyword:
        iconData = Icons.vpn_key;
        color = const Color(0xFFF9E2AF);
        break;
      case CompletionItemKind.variable:
      case CompletionItemKind.field:
      case CompletionItemKind.property:
        iconData = Icons.branding_watermark;
        color = const Color(0xFFA6E3A1);
        break;
      case CompletionItemKind.snippet:
        iconData = Icons.code;
        color = const Color(0xFFF38BA8);
        break;
      case CompletionItemKind.classType:
      case CompletionItemKind.interface:
      case CompletionItemKind.enumType:
        iconData = Icons.class_;
        color = const Color(0xFFFAB387);
        break;
      case CompletionItemKind.file:
      case CompletionItemKind.folder:
        iconData = Icons.folder_open;
        color = const Color(0xFFCBA6F7);
        break;
      default:
        iconData = Icons.text_fields;
        color = const Color(0xFF94E2D5);
    }

    return Icon(iconData, size: 13, color: color);
  }
}
