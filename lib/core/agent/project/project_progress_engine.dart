import 'project_models.dart';

class ProjectProgressEngine {
  const ProjectProgressEngine();

  // Computes deep progress state metrics for the project plan
  ProjectProgress calculateProgress(ProjectPlan plan) {
    var completed = 0;
    var total = 0;

    for (final epic in plan.epics) {
      for (final milestone in epic.milestones) {
        for (final task in milestone.tasks) {
          total++;
          if (task.status == ProjectTaskStatus.completed) {
            completed++;
          }
        }
      }
    }

    final remaining = total - completed;
    final percentage = total == 0 ? 0.0 : (completed / total);
    final velocity = completed * 1.5; // Simulated velocity metric

    return ProjectProgress(
      completionPercentage: percentage,
      completedTasks: completed,
      remainingTasks: remaining,
      velocity: velocity,
      estimatedRemainingWork: Duration(hours: remaining * 2),
      verificationPassRate: percentage,
    );
  }
}
