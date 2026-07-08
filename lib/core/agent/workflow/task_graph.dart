import 'task_step.dart';

class TaskGraph {
  final String id;
  final String goal;
  final List<TaskStep> steps;

  const TaskGraph({
    required this.id,
    required this.goal,
    required this.steps,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'goal': goal,
        'steps': steps.map((s) => s.toJson()).toList(),
      };

  factory TaskGraph.fromJson(Map<String, dynamic> json) => TaskGraph(
        id: json['id'] as String,
        goal: json['goal'] as String,
        steps: (json['steps'] as List)
            .map((s) => TaskStep.fromJson(s as Map<String, dynamic>))
            .toList(),
      );
}
