import '../providers/provider_health.dart';
import 'manifest.dart';

enum PluginState {
  uninstalled,
  installed,
  initialized,
  activated,
  paused,
  disabled,
  failed,
  disposed
}

class HealthReport {
  final ProviderHealth status;
  final DateTime? lastCheck;
  final double latencyMs;
  final String version;
  final List<String> capabilities;
  final List<String> warnings;
  final List<String> errors;

  const HealthReport({
    required this.status,
    this.lastCheck,
    this.latencyMs = 0.0,
    required this.version,
    this.capabilities = const [],
    this.warnings = const [],
    this.errors = const [],
  });
}

class PluginMetrics {
  final int calls;
  final int success;
  final int failures;
  final double averageLatencyMs;
  final int tokens;
  final double cost;
  final Duration uptime;

  const PluginMetrics({
    this.calls = 0,
    this.success = 0,
    this.failures = 0,
    this.averageLatencyMs = 0.0,
    this.tokens = 0,
    this.cost = 0.0,
    this.uptime = Duration.zero,
  });
}

abstract class Integration {
  IntegrationManifest get manifest;
  PluginState get state;
  HealthReport get healthReport;
  PluginMetrics get metrics;

  Future<void> initialize();
  Future<void> beforeActivate();
  Future<void> activate();
  Future<void> afterActivate();
  Future<void> pause();
  Future<void> resume();
  Future<void> deactivate();
  Future<void> beforeDispose();
  Future<void> dispose();
  Future<void> afterDispose();

  Future<Map<String, dynamic>> executeCommand(
      String command, Map<String, dynamic> args);
}
