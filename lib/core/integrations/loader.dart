import 'integration.dart';
import 'plugin_manager.dart';

class IntegrationLoader {
  final PluginManager manager;

  IntegrationLoader(this.manager);

  Future<void> bootstrap(List<Integration> builtins) async {
    for (final integration in builtins) {
      await manager.registerAndActivate(integration);
    }
  }
}
