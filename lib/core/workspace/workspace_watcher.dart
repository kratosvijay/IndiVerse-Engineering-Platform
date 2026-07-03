import 'dart:async';

class WorkspaceWatcher {
  final String rootPath;
  final StreamController<String> _events = StreamController<String>.broadcast();

  bool _isPaused = false;

  WorkspaceWatcher(this.rootPath);

  bool get isPaused => _isPaused;

  Stream<String> get events => _events.stream;

  void start() {
    // Simulated watcher
  }

  void pause() {
    _isPaused = true;
  }

  void resume() {
    _isPaused = false;
  }

  void stop() {
    _events.close();
  }
}
