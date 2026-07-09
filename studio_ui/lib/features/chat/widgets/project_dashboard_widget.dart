import 'package:flutter/material.dart';

class ProjectDashboardWidget extends StatelessWidget {
  final String activeProject;
  final String activeEpic;
  final String activeMilestone;
  final String currentTask;
  final String projectState; // e.g. "planning", "executing", "paused"
  final double completionPercentage;
  final int completedTasks;
  final int remainingTasks;
  final double velocity;
  final List<String> timelineEvents;

  const ProjectDashboardWidget({
    super.key,
    required this.activeProject,
    required this.activeEpic,
    required this.activeMilestone,
    required this.currentTask,
    required this.projectState,
    required this.completionPercentage,
    required this.completedTasks,
    required this.remainingTasks,
    required this.velocity,
    required this.timelineEvents,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                activeProject,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: projectState == 'executing'
                      ? Colors.green.withValues(alpha: 0.2)
                      : Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  projectState.toUpperCase(),
                  style: TextStyle(
                    color: projectState == 'executing'
                        ? Colors.greenAccent
                        : Colors.orangeAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Epic: $activeEpic',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          Text(
            'Milestone: $activeMilestone',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: completionPercentage,
            backgroundColor: const Color(0xFF2C2C2C),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tasks: $completedTasks completed / $remainingTasks remaining',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 11,
                ),
              ),
              Text(
                'Velocity: ${velocity.toStringAsFixed(1)} t/h',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(color: Color(0xFF333333)),
          const SizedBox(height: 6),
          Text(
            'Current Task: $currentTask',
            style: const TextStyle(
              color: Colors.greenAccent,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Project Event Stream:',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          ...timelineEvents.map(
            (evt) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Row(
                children: [
                  const Icon(Icons.bolt, size: 12, color: Colors.blueAccent),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      evt,
                      style: const TextStyle(
                        color: Colors.white30,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
