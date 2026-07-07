import 'package:flutter/material.dart';

class ChatInputController extends ChangeNotifier {
  final TextEditingController textController = TextEditingController();
  final FocusNode focusNode = FocusNode();
  final List<String> _history = [];
  int _historyIndex = -1;

  String get text => textController.text;

  set text(String value) {
    textController.text = value;
    textController.selection = TextSelection.fromPosition(
      TextPosition(offset: value.length),
    );
    notifyListeners();
  }

  void submitPrompt(void Function(String prompt) onSubmit) {
    final prompt = text.trim();
    if (prompt.isNotEmpty) {
      _history.add(prompt);
      _historyIndex = _history.length;
      onSubmit(prompt);
      clear();
    }
  }

  void navigateHistoryUp() {
    if (_history.isNotEmpty && _historyIndex > 0) {
      _historyIndex--;
      text = _history[_historyIndex];
    }
  }

  void navigateHistoryDown() {
    if (_history.isNotEmpty && _historyIndex < _history.length - 1) {
      _historyIndex++;
      text = _history[_historyIndex];
    } else if (_historyIndex == _history.length - 1) {
      _historyIndex = _history.length;
      clear();
    }
  }

  void clear() {
    textController.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    textController.dispose();
    focusNode.dispose();
    super.dispose();
  }
}
