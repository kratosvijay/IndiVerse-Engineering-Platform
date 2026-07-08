import 'package:flutter/material.dart';

class ReasoningBlockWidget extends StatefulWidget {
  final String reasoning;
  final bool initiallyExpanded;

  const ReasoningBlockWidget({
    super.key,
    required this.reasoning,
    this.initiallyExpanded = true,
  });

  @override
  State<ReasoningBlockWidget> createState() => _ReasoningBlockWidgetState();
}

class _ReasoningBlockWidgetState extends State<ReasoningBlockWidget> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.reasoning.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        color: const Color(0xFF252526),
        border: Border.all(color: const Color(0xFF333333)),
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header row (toggles expansion)
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(4.0),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 10.0,
                vertical: 8.0,
              ),
              child: Row(
                children: [
                  Icon(
                    _isExpanded ? Icons.expand_more : Icons.chevron_right,
                    size: 16.0,
                    color: const Color(0xFFCCCCCC),
                  ),
                  const SizedBox(width: 6.0),
                  const Icon(
                    Icons.psychology_outlined,
                    size: 16.0,
                    color: Color(0xFF007ACC),
                  ),
                  const SizedBox(width: 8.0),
                  const Text(
                    'Thinking Process',
                    style: TextStyle(
                      color: Color(0xFFCCCCCC),
                      fontSize: 11.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.only(
                left: 12.0,
                right: 12.0,
                bottom: 10.0,
                top: 4.0,
              ),
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: const BoxDecoration(
                  border: Border(
                    left: BorderSide(color: Color(0xFF007ACC), width: 2.0),
                  ),
                ),
                child: Text(
                  widget.reasoning,
                  style: const TextStyle(
                    color: Color(0xFFAAAAAA),
                    fontSize: 11.0,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
