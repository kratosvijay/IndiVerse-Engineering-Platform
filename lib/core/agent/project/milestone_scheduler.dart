import 'project_models.dart';

abstract interface class SchedulingStrategy {
  List<ProjectTask> schedule(List<ProjectTask> tasks);
}

class PriorityStrategy implements SchedulingStrategy {
  const PriorityStrategy();

  @override
  List<ProjectTask> schedule(List<ProjectTask> tasks) {
    final sorted = List<ProjectTask>.from(tasks);
    sorted.sort((a, b) {
      final pA = _priorityValue(a.priority);
      final pB = _priorityValue(b.priority);
      return pB.compareTo(pA); // Highest first
    });
    return sorted;
  }

  int _priorityValue(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return 3;
      case 'medium':
        return 2;
      case 'low':
        return 1;
      default:
        return 0;
    }
  }
}

class DependencyStrategy implements SchedulingStrategy {
  const DependencyStrategy();

  @override
  List<ProjectTask> schedule(List<ProjectTask> tasks) {
    final ordered = <ProjectTask>[];
    final visited = <String>{};
    final taskMap = {for (final t in tasks) t.id: t};

    void visit(ProjectTask task) {
      if (visited.contains(task.id)) return;
      visited.add(task.id);

      for (final depId in task.dependencies) {
        final depTask = taskMap[depId];
        if (depTask != null) {
          visit(depTask);
        }
      }

      ordered.add(task);
    }

    for (final task in tasks) {
      visit(task);
    }

    return ordered;
  }
}

class MilestoneScheduler {
  final List<SchedulingStrategy> strategies;

  const MilestoneScheduler({
    this.strategies = const [
      DependencyStrategy(),
      PriorityStrategy(),
    ],
  });

  // Re-orders tasks within a Milestone based on dependencies and priorities
  Milestone scheduleMilestone(Milestone milestone) {
    var scheduledTasks = List<ProjectTask>.from(milestone.tasks);
    for (final strategy in strategies) {
      scheduledTasks = strategy.schedule(scheduledTasks);
    }

    return milestone.copyWith(
      tasks: scheduledTasks,
    );
  }
}
