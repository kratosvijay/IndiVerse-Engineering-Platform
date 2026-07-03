import '../../../core/integrations/integration.dart';

class LifecycleDispatcher {
  Future<void> dispatchInitialize(Integration plugin) async {
    await plugin.initialize();
  }

  Future<void> dispatchActivate(Integration plugin) async {
    await plugin.beforeActivate();
    await plugin.activate();
    await plugin.afterActivate();
  }

  Future<void> dispatchDeactivate(Integration plugin) async {
    await plugin.deactivate();
  }

  Future<void> dispatchDispose(Integration plugin) async {
    await plugin.beforeDispose();
    await plugin.dispose();
    await plugin.afterDispose();
  }
}
