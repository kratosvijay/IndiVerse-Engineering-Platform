import 'package:flutter/material.dart';
import '../../../../models/language_intelligence_models.dart';
import '../controllers/signature_help_controller.dart';

class SignatureHelpOverlayWidget extends StatelessWidget {
  final SignatureSession session;
  final SignatureHelpController controller;
  final double globalX;
  final double globalY;

  const SignatureHelpOverlayWidget({
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

    final double overlayWidth = 350.0;
    double left = globalX;
    double top = globalY;

    if (left + overlayWidth > screenWidth) {
      left = screenWidth - overlayWidth - 16;
    }
    if (left < 16) left = 16;

    final help = session.help;
    if (help.signatures.isEmpty) return const SizedBox.shrink();

    final signature = help
        .signatures[help.activeSignature.clamp(0, help.signatures.length - 1)];

    final name = signature.label.contains('(')
        ? signature.label.split('(').first
        : signature.label;
    final spans = <TextSpan>[];

    spans.add(
      const TextSpan(
        text: '(',
        style: TextStyle(color: Color(0xFFD9E0EE)),
      ),
    );

    if (signature.parameters.isNotEmpty) {
      spans.add(const TextSpan(text: '\n'));
      for (int i = 0; i < signature.parameters.length; i++) {
        final param = signature.parameters[i];
        final isActive = i == help.activeParameter;

        spans.add(const TextSpan(text: '    '));

        spans.add(
          TextSpan(
            text: param.label,
            style: TextStyle(
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive
                  ? const Color(0xFFFAB387)
                  : const Color(0xFFD9E0EE),
              decoration: isActive ? TextDecoration.underline : null,
            ),
          ),
        );

        if (i < signature.parameters.length - 1) {
          spans.add(
            const TextSpan(
              text: ',\n',
              style: TextStyle(color: Color(0xFFD9E0EE)),
            ),
          );
        } else {
          spans.add(const TextSpan(text: '\n'));
        }
      }
    }

    spans.add(
      const TextSpan(
        text: ')',
        style: TextStyle(color: Color(0xFFD9E0EE)),
      ),
    );

    final activeParamDoc =
        (help.activeParameter >= 0 &&
            help.activeParameter < signature.parameters.length)
        ? signature.parameters[help.activeParameter].documentation
        : null;
    final docText = activeParamDoc ?? signature.documentation;

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: name,
                            style: const TextStyle(
                              color: Color(0xFF89B4FA),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              fontFamily: 'Courier',
                            ),
                          ),
                          TextSpan(
                            children: spans,
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'Courier',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (docText != null && docText.isNotEmpty) ...[
                Container(height: 1, color: const Color(0xFF3F3F56)),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (activeParamDoc != null) ...[
                        Text(
                          signature.parameters[help.activeParameter].label,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFAB387),
                            fontFamily: 'Courier',
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        docText,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFFB0B0B0),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
