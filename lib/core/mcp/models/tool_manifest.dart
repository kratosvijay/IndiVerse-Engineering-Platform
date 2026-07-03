import 'permission.dart';

class ToolManifest {
  final String id;
  final String version;
  final String description;
  final List<Permission> permissions;
  final double estimatedCost;
  final Duration timeout;

  const ToolManifest({
    required this.id,
    required this.version,
    required this.description,
    required this.permissions,
    required this.estimatedCost,
    required this.timeout,
  });
}
