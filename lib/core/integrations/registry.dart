import 'integration.dart';
import 'capability.dart';
import '../providers/provider_health.dart';

class IntegrationRegistry {
  final Map<String, Integration> _integrations = {};

  void register(Integration integration) {
    _integrations[integration.manifest.id] = integration;
  }

  void unregister(String id) {
    _integrations.remove(id);
  }

  List<Integration> listInstalled() => _integrations.values.toList();

  List<Integration> listAvailable() => _integrations.values
      .where((i) =>
          i.state != PluginState.uninstalled && i.state != PluginState.disposed)
      .toList();

  List<Integration> getByCapability(IntegrationCapability capability) {
    return _integrations.values
        .where((i) => i.manifest.capabilities.contains(capability))
        .toList();
  }

  Integration? findBest(IntegrationCapability capability) {
    final candidates = getByCapability(capability);
    if (candidates.isEmpty) return null;
    candidates
        .sort((a, b) => b.manifest.priority.compareTo(a.manifest.priority));
    return candidates.first;
  }

  List<Integration> findHealthy(IntegrationCapability capability) {
    return getByCapability(capability)
        .where((i) => i.healthReport.status == ProviderHealth.healthy)
        .toList();
  }

  Map<String, String> healthSummary() {
    final summary = <String, String>{};
    for (final integration in _integrations.values) {
      summary[integration.manifest.id] =
          integration.healthReport.status.toString().split('.').last;
    }
    return summary;
  }
}
