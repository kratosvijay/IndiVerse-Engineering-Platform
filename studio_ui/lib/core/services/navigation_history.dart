class NavigationLocation {
  final String path;
  final int line;
  final int column;
  final DateTime timestamp;

  const NavigationLocation({
    required this.path,
    required this.line,
    required this.column,
    required this.timestamp,
  });
}

class NavigationHistory {
  static const int maxCapacity = 200;
  final List<NavigationLocation> _history = [];
  int _currentIndex = -1;

  List<NavigationLocation> get entries => List.unmodifiable(_history);
  int get currentIndex => _currentIndex;

  void record(String path, int line, int column) {
    final now = DateTime.now();

    // Check if we are duplicating the current location
    if (_currentIndex >= 0 && _currentIndex < _history.length) {
      final current = _history[_currentIndex];
      if (current.path == path && (current.line - line).abs() < 5) {
        // Line number change is too small to record, or same file
        return;
      }
    }

    // Discard any forward history if we navigated back and then recorded a new location
    if (_currentIndex < _history.length - 1) {
      _history.removeRange(_currentIndex + 1, _history.length);
    }

    // Keep capacity bounded to 200
    if (_history.length >= maxCapacity) {
      _history.removeAt(0);
      _currentIndex--;
    }

    _history.add(
      NavigationLocation(
        path: path,
        line: line,
        column: column,
        timestamp: now,
      ),
    );
    _currentIndex = _history.length - 1;
  }

  NavigationLocation? goBack() {
    if (_currentIndex > 0) {
      _currentIndex--;
      return _history[_currentIndex];
    }
    return null;
  }

  NavigationLocation? goForward() {
    if (_currentIndex < _history.length - 1) {
      _currentIndex++;
      return _history[_currentIndex];
    }
    return null;
  }

  void clear() {
    _history.clear();
    _currentIndex = -1;
  }
}
