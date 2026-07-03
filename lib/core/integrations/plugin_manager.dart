import 'dart:async';
import 'package:indiverse_developer_platform/sdk/public/plugin_sdk.dart';
import 'integration.dart';
import 'registry.dart';
import 'compatibility/runtime_compatibility.dart';
import 'compatibility/platform_compatibility.dart';
import 'compatibility/dependency_compatibility.dart';
import 'package:indiverse_developer_platform/sdk/internal/lifecycle_dispatcher.dart';

class PluginManager {
  final IntegrationRegistry registry;
  final PluginContext context;
  final LifecycleDispatcher dispatcher = LifecycleDispatcher();

  final RuntimeCompatibilityValidator runtimeValidator =
      RuntimeCompatibilityValidator();
  final PlatformCompatibilityValidator platformValidator =
      PlatformCompatibilityValidator();
  final DependencyCompatibilityValidator dependencyValidator =
      DependencyCompatibilityValidator();

  final Map<String, PluginState> _states = {};

  PluginManager({required this.registry, required this.context});

  PluginState getPluginState(String id) =>
      _states[id] ?? PluginState.uninstalled;

  Future<bool> registerAndActivate(Integration integration) async {
    final manifest = integration.manifest;
    final id = manifest.id;

    if (!runtimeValidator.check(manifest) ||
        !platformValidator.check(manifest) ||
        !dependencyValidator.check(manifest)) {
      _states[id] = PluginState.failed;
      return false;
    }

    registry.register(integration);
    _states[id] = PluginState.installed;

    try {
      await dispatcher.dispatchInitialize(integration);
      _states[id] = PluginState.initialized;

      await dispatcher.dispatchActivate(integration);
      _states[id] = PluginState.activated;

      return true;
    } catch (e) {
      _states[id] = PluginState.failed;
      return false;
    }
  }

  Future<void> deactivateAndUnregister(String id) async {
    final integration =
        registry.listInstalled().firstWhere((i) => i.manifest.id == id);
    await integration.deactivate();
    _states[id] = PluginState.disabled;

    await dispatcher.dispatchDispose(integration);
    _states[id] = PluginState.disposed;

    registry.unregister(id);
  }
}
