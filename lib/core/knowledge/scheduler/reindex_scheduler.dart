import 'dart:async';

class ReindexScheduler {
  final List<String> _queue = [];
  bool _isProcessing = false;

  void schedule(String path) {
    _queue.add(path);
    _trigger();
  }

  void _trigger() {
    if (_isProcessing) return;
    _isProcessing = true;
    Timer(const Duration(milliseconds: 500), () {
      _queue.clear();
      _isProcessing = false;
    });
  }
}
