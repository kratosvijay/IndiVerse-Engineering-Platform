class RuntimeManifest {
  final String runtimeVersion;
  final List<String> supportedProviders;
  final List<String> activePlugins;
  final List<String> activeMiddleware;
  final List<String> supportedCapabilities;

  const RuntimeManifest({
    required this.runtimeVersion,
    required this.supportedProviders,
    required this.activePlugins,
    required this.activeMiddleware,
    required this.supportedCapabilities,
  });
}
