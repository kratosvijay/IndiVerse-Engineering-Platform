import 'package:indiverse_developer_platform/sdk/public/plugin_sdk.dart';
import '../../../../providers/provider_health.dart';
import '../../../integration.dart';
import '../../../manifest.dart';
import '../../../capability.dart';
import '../../../category.dart';

class AiderTemplate implements Integration {
  final PluginContext context;
  PluginState _state = PluginState.uninstalled;
  HealthReport _health =
      const HealthReport(status: ProviderHealth.unknown, version: "1.0.0");
  PluginMetrics _metrics = const PluginMetrics();

  AiderTemplate(this.context);

  @override
  IntegrationManifest get manifest => const IntegrationManifest(
        id: "aider",
        name: "Aider Template Plugin",
        vendor: "Community",
        version: "1.0.0",
        homepage: "https://github.com",
        license: "MIT",
        category: IntegrationCategory.tool,
        capabilities: {
          IntegrationCapability.toolExecution,
        },
        source: PluginInstallationSource.local,
      );

  @override
  PluginState get state => _state;

  @override
  HealthReport get healthReport => _health;

  @override
  PluginMetrics get metrics => _metrics;

  @override
  Future<void> initialize() async {
    _state = PluginState.initialized;
  }

  @override
  Future<void> beforeActivate() async {}

  @override
  Future<void> activate() async {
    _state = PluginState.activated;
    _health =
        const HealthReport(status: ProviderHealth.healthy, version: "1.0.0");
  }

  @override
  Future<void> afterActivate() async {}

  @override
  Future<void> pause() async {
    _state = PluginState.paused;
  }

  @override
  Future<void> resume() async {
    _state = PluginState.activated;
  }

  @override
  Future<void> deactivate() async {
    _state = PluginState.disabled;
  }

  @override
  Future<void> beforeDispose() async {}

  @override
  Future<void> dispose() async {
    _state = PluginState.disposed;
  }

  @override
  Future<void> afterDispose() async {}

  @override
  Future<Map<String, dynamic>> executeCommand(
      String command, Map<String, dynamic> args) async {
    return {"status": "not_implemented"};
  }
}
