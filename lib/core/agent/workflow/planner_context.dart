class PlannerContext {
  final String goal;
  final String workspacePath;
  final String conversationId;
  final List<dynamic> diagnostics;
  final String? selectedCode;
  final Map<String, bool> providerCapabilities;

  const PlannerContext({
    required this.goal,
    required this.workspacePath,
    required this.conversationId,
    this.diagnostics = const [],
    this.selectedCode,
    this.providerCapabilities = const {},
  });

  Map<String, dynamic> toJson() => {
        'goal': goal,
        'workspacePath': workspacePath,
        'conversationId': conversationId,
        'diagnostics': diagnostics,
        'selectedCode': selectedCode,
        'providerCapabilities': providerCapabilities,
      };

  factory PlannerContext.fromJson(Map<String, dynamic> json) => PlannerContext(
        goal: json['goal'] as String,
        workspacePath: json['workspacePath'] as String,
        conversationId: json['conversationId'] as String,
        diagnostics: List<dynamic>.from(json['diagnostics'] as Iterable? ?? []),
        selectedCode: json['selectedCode'] as String?,
        providerCapabilities:
            Map<String, bool>.from(json['providerCapabilities'] as Map? ?? {}),
      );
}
