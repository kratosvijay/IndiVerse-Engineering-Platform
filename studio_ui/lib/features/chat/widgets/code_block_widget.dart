import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CodeBlockWidget extends StatefulWidget {
  final String language;
  final String code;
  final void Function(String code)? onInsert;

  const CodeBlockWidget({
    super.key,
    required this.language,
    required this.code,
    this.onInsert,
  });

  @override
  State<CodeBlockWidget> createState() => _CodeBlockWidgetState();
}

class _CodeBlockWidgetState extends State<CodeBlockWidget> {
  bool _isCollapsed = false;
  bool _isCopied = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        border: Border.all(color: const Color(0xFF333333)),
        borderRadius: BorderRadius.circular(6.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 6.0,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF252526),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(5.0),
                topRight: Radius.circular(5.0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      widget.language.toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF858585),
                        fontWeight: FontWeight.bold,
                        fontSize: 11.0,
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    IconButton(
                      iconSize: 14.0,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        _isCollapsed
                            ? Icons.keyboard_arrow_down
                            : Icons.keyboard_arrow_up,
                        color: const Color(0xFF858585),
                      ),
                      onPressed: () {
                        setState(() {
                          _isCollapsed = !_isCollapsed;
                        });
                      },
                    ),
                  ],
                ),
                Row(
                  children: [
                    // Copy button
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0),
                        minimumSize: Size.zero,
                      ),
                      icon: Icon(
                        _isCopied ? Icons.check : Icons.copy,
                        size: 13.0,
                        color: const Color(0xFF858585),
                      ),
                      label: Text(
                        _isCopied ? 'Copied' : 'Copy',
                        style: const TextStyle(
                          color: Color(0xFF858585),
                          fontSize: 11.0,
                        ),
                      ),
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: widget.code),
                        );
                        setState(() {
                          _isCopied = true;
                        });
                        Future.delayed(const Duration(seconds: 2), () {
                          if (mounted) {
                            setState(() {
                              _isCopied = false;
                            });
                          }
                        });
                      },
                    ),
                    const SizedBox(width: 8.0),
                    // Insert into Editor button (if callback is present)
                    if (widget.onInsert != null)
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 6.0),
                          minimumSize: Size.zero,
                        ),
                        icon: const Icon(
                          Icons.arrow_back,
                          size: 13.0,
                          color: Color(0xFF858585),
                        ),
                        label: const Text(
                          'Insert',
                          style: TextStyle(
                            color: Color(0xFF858585),
                            fontSize: 11.0,
                          ),
                        ),
                        onPressed: () => widget.onInsert!(widget.code),
                      ),
                  ],
                ),
              ],
            ),
          ),
          // Code Display Area
          if (!_isCollapsed)
            Container(
              padding: const EdgeInsets.all(12.0),
              color: const Color(0xFF1E1E1E),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(
                  widget.code,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    color: Color(0xFFD4D4D4),
                    fontSize: 12.0,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
