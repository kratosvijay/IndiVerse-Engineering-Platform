import 'package:flutter/material.dart';
import '../../../models/ai_models.dart';
import '../controllers/chat_controller.dart';

class TaskExecutionWidget extends StatelessWidget {
  final ChatController controller;

  const TaskExecutionWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final graph = controller.activePlanGraph;
    final session = controller.activePlanSession;

    if (graph == null) {
      return const SizedBox.shrink();
    }

    final hasSession = session != null;
    final progress = session?.progress ?? 0.0;
    final status = session?.status ?? PlanStatus.ready;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E).withOpacity(0.85),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color(0xFF333333)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header section
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                const Icon(
                  Icons.playlist_play,
                  color: Colors.blueAccent,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Task Plan: ${graph.goal}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Status: ${status.name.toUpperCase()}',
                        style: TextStyle(
                          color: _getStatusColor(status),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildActionButtons(status),
              ],
            ),
          ),

          // Progress bar
          if (hasSession) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: const Color(0xFF333333),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Colors.blueAccent,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Steps list
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: graph.steps.length,
            separatorBuilder: (context, index) =>
                const Divider(color: Color(0xFF333333), height: 1),
            itemBuilder: (context, index) {
              final step = graph.steps[index];
              final stepState = session?.stepStates[step.id];
              final stepStatus = stepState?.status ?? StepStatus.pending;

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 10.0,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStepStatusIcon(stepStatus),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step.title,
                            style: TextStyle(
                              color: stepStatus == StepStatus.completed
                                  ? Colors.white.withOpacity(0.5)
                                  : Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              decoration: stepStatus == StepStatus.completed
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          if (stepState?.error != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              stepState.error!,
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 11,
                              ),
                            ),
                          ] else if (stepState?.output != null &&
                              stepState.output!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              stepState.output!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Color _getStatusColor(PlanStatus status) {
    switch (status) {
      case PlanStatus.running:
        return Colors.blueAccent;
      case PlanStatus.completed:
        return Colors.green;
      case PlanStatus.failed:
        return Colors.redAccent;
      case PlanStatus.paused:
      case PlanStatus.waitingPermission:
      case PlanStatus.waitingUser:
        return Colors.amber;
      default:
        return Colors.white54;
    }
  }

  Widget _buildStepStatusIcon(StepStatus status) {
    switch (status) {
      case StepStatus.pending:
        return const Icon(
          Icons.circle_outlined,
          color: Colors.white30,
          size: 18,
        );
      case StepStatus.running:
        return const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
          ),
        );
      case StepStatus.completed:
        return const Icon(Icons.check_circle, color: Colors.green, size: 18);
      case StepStatus.failed:
        return const Icon(Icons.cancel, color: Colors.redAccent, size: 18);
      case StepStatus.skipped:
        return const Icon(
          Icons.next_plan_outlined,
          color: Colors.white30,
          size: 18,
        );
    }
  }

  Widget _buildActionButtons(PlanStatus status) {
    if (status == PlanStatus.ready) {
      return ElevatedButton.icon(
        onPressed: controller.executeActivePlan,
        icon: const Icon(Icons.play_arrow, size: 14),
        label: const Text('Run'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (status == PlanStatus.running)
          IconButton(
            icon: const Icon(Icons.pause, color: Colors.amber, size: 18),
            tooltip: 'Pause',
            onPressed: controller.pauseActivePlan,
          ),
        if (status == PlanStatus.paused ||
            status == PlanStatus.waitingPermission) ...[
          IconButton(
            icon: const Icon(Icons.play_arrow, color: Colors.green, size: 18),
            tooltip: 'Resume',
            onPressed: controller.resumeActivePlan,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.blueAccent, size: 18),
            tooltip: 'Retry',
            onPressed: controller.retryActivePlan,
          ),
        ],
        if (status == PlanStatus.failed)
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.blueAccent, size: 18),
            tooltip: 'Retry failed step',
            onPressed: controller.retryActivePlan,
          ),
        if (status == PlanStatus.running ||
            status == PlanStatus.paused ||
            status == PlanStatus.waitingPermission ||
            status == PlanStatus.failed)
          IconButton(
            icon: const Icon(Icons.stop, color: Colors.redAccent, size: 18),
            tooltip: 'Cancel',
            onPressed: controller.cancelActivePlan,
          ),
      ],
    );
  }
}
