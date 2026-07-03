import 'capability.dart';
import 'category.dart';

enum PluginInstallationSource { builtin, marketplace, git, local, zip }

class IntegrationManifest {
  final String id;
  final String name;
  final String vendor;
  final String version;
  final String homepage;
  final String license;
  final IntegrationCategory category;

  final String minRuntimeVersion;
  final String maxRuntimeVersion;
  final String sdkVersion;
  final List<String> supportedPlatforms;

  final Set<IntegrationCapability> capabilities;
  final List<String> dependencies;
  final List<String> optionalDependencies;
  final List<String> recommendedDependencies;
  final List<String> conflicts;

  final Set<String> permissions;
  final PluginInstallationSource source;
  final int priority;

  final String? signature;
  final String? publisher;
  final String? checksum;

  const IntegrationManifest({
    required this.id,
    required this.name,
    required this.vendor,
    required this.version,
    required this.homepage,
    required this.license,
    required this.category,
    this.minRuntimeVersion = "0.3.0",
    this.maxRuntimeVersion = "2.0.0",
    this.sdkVersion = "1.0.0",
    this.supportedPlatforms = const ["macos", "linux", "windows"],
    required this.capabilities,
    this.dependencies = const [],
    this.optionalDependencies = const [],
    this.recommendedDependencies = const [],
    this.conflicts = const [],
    this.permissions = const {},
    this.source = PluginInstallationSource.builtin,
    this.priority = 100,
    this.signature,
    this.publisher,
    this.checksum,
  });
}
