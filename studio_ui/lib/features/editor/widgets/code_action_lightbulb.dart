import 'package:flutter/material.dart';
import '../controllers/code_action_controller.dart';

class CodeActionLightbulb extends StatelessWidget {
  final CodeActionSession session;
  final CodeActionController controller;
  final double globalX;
  final double globalY;

  const CodeActionLightbulb({
    super.key,
    required this.session,
    required this.controller,
    required this.globalX,
    required this.globalY,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: globalX,
      top: globalY,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            session.isVisible = true;
            controller.state.refreshUI();
          },
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF2E2E3E),
              border: Border.all(color: const Color(0xFFFAB387), width: 1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(
              Icons.lightbulb,
              color: Color(0xFFF9E2AF),
              size: 16,
            ),
          ),
        ),
      ),
    );
  }
}
