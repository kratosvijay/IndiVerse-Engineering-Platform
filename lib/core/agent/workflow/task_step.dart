import 'dart:core';

enum StepType { tool, ai, human, condition }

class ExecutionPolicy {
  final int maxRetries;
  final Duration timeout;
  final bool continueOnFailure;

  const ExecutionPolicy({
    this.maxRetries = 3,
    this.timeout = const Duration(minutes: 5),
    this.continueOnFailure = false,
  });

  Map<String, dynamic> toJson() => {
        'maxRetries': maxRetries,
        'timeoutMs': timeout.inMilliseconds,
        'continueOnFailure': continueOnFailure,
      };

  factory ExecutionPolicy.fromJson(Map<String, dynamic> json) =>
      ExecutionPolicy(
        maxRetries: json['maxRetries'] as int? ?? 3,
        timeout: Duration(milliseconds: json['timeoutMs'] as int? ?? 300000),
        continueOnFailure: json['continueOnFailure'] as bool? ?? false,
      );
}

class TaskStep {
  final String id;
  final String title;
  final StepType type;
  final String? toolId;
  final Map<String, dynamic>? arguments;
  final List<String> dependencies;
  final ExecutionPolicy policy;

  const TaskStep({
    required this.id,
    required this.title,
    this.type = StepType.tool,
    this.toolId,
    this.arguments,
    this.dependencies = const [],
    this.policy = const ExecutionPolicy(),
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'type': type.name,
        'toolId': toolId,
        'arguments': arguments,
        'dependencies': dependencies,
        'policy': policy.toJson(),
      };

  factory TaskStep.fromJson(Map<String, dynamic> json) => TaskStep(
        id: json['id'] as String,
        title: json['title'] as String,
        type: StepType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => StepType.tool,
        ),
        toolId: json['toolId'] as String?,
        arguments: json['arguments'] != null
            ? Map<String, dynamic>.from(json['arguments'] as Map)
            : null,
        dependencies:
            List<String>.from(json['dependencies'] as Iterable? ?? []),
        policy: json['policy'] != null
            ? ExecutionPolicy.fromJson(json['policy'] as Map<String, dynamic>)
            : const ExecutionPolicy(),
      );
}
