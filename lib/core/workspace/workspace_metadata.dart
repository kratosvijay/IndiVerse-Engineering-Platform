class WorkspaceMetadata {
  final String projectName;
  final String organization;
  final String primaryLanguage;
  final String architecture;
  final List<String> rules;
  final List<String> adrs;
  final DateTime created;
  final DateTime lastIndexed;
  final String platformVersion;

  const WorkspaceMetadata({
    required this.projectName,
    required this.organization,
    required this.primaryLanguage,
    required this.architecture,
    required this.rules,
    required this.adrs,
    required this.created,
    required this.lastIndexed,
    required this.platformVersion,
  });
}
