class PluginConfiguration {
  final Map<String, dynamic> defaults;
  final Set<String> requiredFields;
  final Map<String, String> environmentOverrides;

  const PluginConfiguration({
    this.defaults = const {},
    this.requiredFields = const {},
    this.environmentOverrides = const {},
  });

  bool validate(Map<String, dynamic> config) {
    for (final field in requiredFields) {
      if (!config.containsKey(field)) return false;
    }
    return true;
  }
}
