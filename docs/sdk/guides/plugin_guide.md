# Plugin Development Guide

This guide describes how to construct a new plugin integration for the **IndiVerse Developer Platform (IDP)**.

## Core Abstractions

Every plugin requires two items:
1. An implementation of the `Integration` interface.
2. A `PluginBuilder` binding that generates the integration instance.

```dart
import 'package:indiverse_developer_platform/sdk/public/plugin_sdk.dart';
import 'package:indiverse_developer_platform/core/integrations/integration.dart';
import 'package:indiverse_developer_platform/core/integrations/manifest.dart';
import 'package:indiverse_developer_platform/core/integrations/capability.dart';
import 'package:indiverse_developer_platform/core/integrations/category.dart';

class HelloPlugin implements Integration {
  final PluginContext context;
  PluginState _state = PluginState.uninstalled;
  HealthReport _health = const HealthReport(status: ProviderHealth.unknown, version: "1.0.0");
  PluginMetrics _metrics = const PluginMetrics();

  HelloPlugin(this.context);

  @override
  IntegrationManifest get manifest => const IntegrationManifest(
    id: "hello-plugin",
    name: "Hello Plugin",
    vendor: "IndiVerse",
    version: "1.0.0",
    homepage: "https://github.com",
    license: "MIT",
    category: IntegrationCategory.tool,
    capabilities: {
      IntegrationCapability.toolExecution,
    },
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
    _health = const HealthReport(status: ProviderHealth.healthy, version: "1.0.0");
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
  Future<Map<String, dynamic>> executeCommand(String command, Map<String, dynamic> args) async {
    return {"message": "Hello World!"};
  }
}
```
