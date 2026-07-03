import '../../events/runtime_event.dart';

class PluginLoaded extends RuntimeEvent {
  final String pluginId;

  PluginLoaded({
    required DateTime timestamp,
    required String eventId,
    required this.pluginId,
  }) : super(timestamp: timestamp, eventId: eventId);
}

class PluginActivated extends RuntimeEvent {
  final String pluginId;

  PluginActivated({
    required DateTime timestamp,
    required String eventId,
    required this.pluginId,
  }) : super(timestamp: timestamp, eventId: eventId);
}

class PluginDeactivated extends RuntimeEvent {
  final String pluginId;

  PluginDeactivated({
    required DateTime timestamp,
    required String eventId,
    required this.pluginId,
  }) : super(timestamp: timestamp, eventId: eventId);
}

class PluginFailed extends RuntimeEvent {
  final String pluginId;
  final String error;

  PluginFailed({
    required DateTime timestamp,
    required String eventId,
    required this.pluginId,
    required this.error,
  }) : super(timestamp: timestamp, eventId: eventId);
}

class CapabilityRegistered extends RuntimeEvent {
  final String pluginId;
  final String capability;

  CapabilityRegistered({
    required DateTime timestamp,
    required String eventId,
    required this.pluginId,
    required this.capability,
  }) : super(timestamp: timestamp, eventId: eventId);
}

class CompatibilityFailed extends RuntimeEvent {
  final String pluginId;
  final String reason;

  CompatibilityFailed({
    required DateTime timestamp,
    required String eventId,
    required this.pluginId,
    required this.reason,
  }) : super(timestamp: timestamp, eventId: eventId);
}

class PermissionDenied extends RuntimeEvent {
  final String pluginId;
  final String permission;

  PermissionDenied({
    required DateTime timestamp,
    required String eventId,
    required this.pluginId,
    required this.permission,
  }) : super(timestamp: timestamp, eventId: eventId);
}
