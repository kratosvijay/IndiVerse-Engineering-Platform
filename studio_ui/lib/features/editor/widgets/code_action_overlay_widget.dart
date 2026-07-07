import 'package:flutter/material.dart';
import '../../../../models/language_intelligence_models.dart';
import '../controllers/code_action_controller.dart';

class CodeActionOverlayWidget extends StatelessWidget {
  final CodeActionSession session;
  final CodeActionController controller;
  final double globalX;
  final double globalY;

  const CodeActionOverlayWidget({
    super.key,
    required this.session,
    required this.controller,
    required this.globalX,
    required this.globalY,
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;

    const double overlayWidth = 280.0;
    double left = globalX;
    double top = globalY;

    if (left + overlayWidth > screenWidth) {
      left = screenWidth - overlayWidth - 16;
    }
    if (left < 16) left = 16;

    final actions = session.actions;

    return Positioned(
      left: left,
      top: top,
      width: overlayWidth,
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2E),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF3F3F56), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFF181825),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lightbulb,
                      color: Color(0xFFF9E2AF),
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Quick Fixes & Refactoring',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Actions List
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: actions.length,
                  itemBuilder: (context, index) {
                    final action = actions[index];
                    final isSelected = index == session.selectedIndex;

                    IconData iconData = Icons.build;
                    Color iconColor = const Color(0xFF89B4FA);

                    if (action.kind == CodeActionKind.sourceOrganizeImports) {
                      iconData = Icons.sort;
                      iconColor = const Color(0xFFA6E3A1);
                    } else if (action.kind == CodeActionKind.sourceFixAll) {
                      iconData = Icons.auto_awesome;
                      iconColor = const Color(0xFFF5C2E7);
                    } else if (action.isPreferred) {
                      iconData = Icons.offline_bolt;
                      iconColor = const Color(0xFFFAB387);
                    }

                    return InkWell(
                      onTap: () {
                        session.selectedIndex = index;
                        controller.executeSelectedAction();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        color: isSelected
                            ? const Color(0xFF313244)
                            : Colors.transparent,
                        child: Row(
                          children: [
                            Icon(iconData, color: iconColor, size: 16),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    action.title,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : const Color(0xFFCDD6F4),
                                      fontSize: 12,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  if (action.disabledReason != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2.0),
                                      child: Text(
                                        action.disabledReason!,
                                        style: const TextStyle(
                                          color: Color(0xFFF38BA8),
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
