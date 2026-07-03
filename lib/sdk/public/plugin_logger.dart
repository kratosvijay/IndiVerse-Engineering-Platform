class PluginLogger {
  final String pluginId;
  final List<String> _logs = [];

  PluginLogger(this.pluginId);

  List<String> get logs => List.unmodifiable(_logs);

  void log(String message) {
    _logs.add("[${DateTime.now().toIso8601String()}] [$pluginId] $message");
  }
}
