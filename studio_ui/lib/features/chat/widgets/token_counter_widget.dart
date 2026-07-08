import 'package:flutter/material.dart';

class TokenCounterWidget extends StatefulWidget {
  final TextEditingController controller;

  const TokenCounterWidget({super.key, required this.controller});

  @override
  State<TokenCounterWidget> createState() => _TokenCounterWidgetState();
}

class _TokenCounterWidgetState extends State<TokenCounterWidget> {
  int _estimatedTokens = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_updateTokenCount);
    _updateTokenCount();
  }

  @override
  void didUpdateWidget(covariant TokenCounterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_updateTokenCount);
      widget.controller.addListener(_updateTokenCount);
      _updateTokenCount();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateTokenCount);
    super.dispose();
  }

  void _updateTokenCount() {
    final text = widget.controller.text;
    if (text.isEmpty) {
      setState(() {
        _estimatedTokens = 0;
      });
      return;
    }

    // A simple, reliable estimation: ~4 characters per token
    final estimated = (text.length / 4.0).ceil();
    setState(() {
      _estimatedTokens = estimated;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_estimatedTokens == 0) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4.0, right: 4.0),
      child: Text(
        '$_estimatedTokens tokens',
        style: const TextStyle(
          color: Color(0xFF6E6E6E),
          fontSize: 10.0,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
