import 'dart:async';
import '../../../core/events/event_bus.dart';
import '../../../core/security/credential_manager.dart';
import '../../../core/runtime/runtime.dart';
import 'plugin_logger.dart';
import 'plugin_storage.dart';
import 'plugin_configuration.dart';

class WorkspaceInfo {
  final String project;
  final String repository;
  final String branch;
  final String environment;

  const WorkspaceInfo({
    required this.project,
    required this.repository,
    required this.branch,
    required this.environment,
  });
}

class PluginContext {
  final String pluginId;
  final String correlationId;
  final PluginLogger logger;
  final PluginStorage storage;
  final PluginConfiguration configuration;
  final EventBus eventBus;
  final CredentialManager credentialManager;
  final Runtime runtime;
  final WorkspaceInfo workspace;
  final Completer<void> cancellationToken;

  PluginContext({
    required this.pluginId,
    required this.correlationId,
    required this.logger,
    required this.storage,
    required this.configuration,
    required this.eventBus,
    required this.credentialManager,
    required this.runtime,
    required this.workspace,
    required this.cancellationToken,
  });
}
