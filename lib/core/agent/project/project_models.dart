import '../generation/generation_models.dart';
import '../verification/verification_models.dart';

enum ProjectState {
  created,
  planning,
  executing,
  paused,
  waitingForUser,
  blocked,
  verifying,
  completed,
  failed,
  archived
}

enum ProjectTaskStatus {
  todo,
  inProgress,
  blocked,
  completed,
  failed
}

class ProjectTask {
  final String id;
  final String title;
  final String description;
  final String priority; // High, Medium, Low
  final ProjectTaskStatus status;
  final List<String> dependencies;

  const ProjectTask({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    required this.dependencies,
  });

  ProjectTask copyWith({
    String? id,
    String? title,
    String? description,
    String? priority,
    ProjectTaskStatus? status,
    List<String>? dependencies,
  }) {
    return ProjectTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      dependencies: dependencies ?? this.dependencies,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'priority': priority,
        'status': status.name,
        'dependencies': dependencies,
      };

  factory ProjectTask.fromJson(Map<String, dynamic> json) => ProjectTask(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        priority: json['priority'] as String,
        status: ProjectTaskStatus.values.firstWhere((e) => e.name == json['status']),
        dependencies: List<String>.from(json['dependencies'] as List),
      );
}

class Milestone {
  final String id;
  final String title;
  final String description;
  final List<ProjectTask> tasks;
  final bool isCompleted;

  const Milestone({
    required this.id,
    required this.title,
    required this.description,
    required this.tasks,
    required this.isCompleted,
  });

  Milestone copyWith({
    String? id,
    String? title,
    String? description,
    List<ProjectTask>? tasks,
    bool? isCompleted,
  }) {
    return Milestone(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      tasks: tasks ?? this.tasks,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'tasks': tasks.map((t) => t.toJson()).toList(),
        'isCompleted': isCompleted,
      };

  factory Milestone.fromJson(Map<String, dynamic> json) => Milestone(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        tasks: (json['tasks'] as List)
            .map((t) => ProjectTask.fromJson(t as Map<String, dynamic>))
            .toList(),
        isCompleted: json['isCompleted'] as bool,
      );
}

class Epic {
  final String id;
  final String title;
  final String description;
  final List<Milestone> milestones;

  const Epic({
    required this.id,
    required this.title,
    required this.description,
    required this.milestones,
  });

  Epic copyWith({
    String? id,
    String? title,
    String? description,
    List<Milestone>? milestones,
  }) {
    return Epic(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      milestones: milestones ?? this.milestones,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'milestones': milestones.map((m) => m.toJson()).toList(),
      };

  factory Epic.fromJson(Map<String, dynamic> json) => Epic(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        milestones: (json['milestones'] as List)
            .map((m) => Milestone.fromJson(m as Map<String, dynamic>))
            .toList(),
      );
}

class ProjectPlan {
  final String id;
  final int version;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Epic> epics;
  final ProjectState state;

  const ProjectPlan({
    required this.id,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
    required this.epics,
    required this.state,
  });

  ProjectPlan copyWith({
    String? id,
    int? version,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Epic>? epics,
    ProjectState? state,
  }) {
    return ProjectPlan(
      id: id ?? this.id,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      epics: epics ?? this.epics,
      state: state ?? this.state,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'version': version,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'epics': epics.map((e) => e.toJson()).toList(),
        'state': state.name,
      };

  factory ProjectPlan.fromJson(Map<String, dynamic> json) => ProjectPlan(
        id: json['id'] as String,
        version: json['version'] as int,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        epics: (json['epics'] as List)
            .map((e) => Epic.fromJson(e as Map<String, dynamic>))
            .toList(),
        state: ProjectState.values.firstWhere((e) => e.name == json['state']),
      );
}

class ExecutionCheckpoint {
  final String checkpointId;
  final String projectId;
  final DateTime timestamp;
  final String workspaceSnapshotId;
  final List<GeneratedPatch> patches;
  final VerificationReport? verificationReport;

  const ExecutionCheckpoint({
    required this.checkpointId,
    required this.projectId,
    required this.timestamp,
    required this.workspaceSnapshotId,
    required this.patches,
    this.verificationReport,
  });

  Map<String, dynamic> toJson() => {
        'checkpointId': checkpointId,
        'projectId': projectId,
        'timestamp': timestamp.toIso8601String(),
        'workspaceSnapshotId': workspaceSnapshotId,
        'patches': patches.map((p) => p.toJson()).toList(),
        'verificationReport': verificationReport?.toJson(),
      };
}

class ProjectProgress {
  final double completionPercentage;
  final int completedTasks;
  final int remainingTasks;
  final double velocity; // Tasks completed per hour
  final Duration estimatedRemainingWork;
  final double verificationPassRate;

  const ProjectProgress({
    required this.completionPercentage,
    required this.completedTasks,
    required this.remainingTasks,
    required this.velocity,
    required this.estimatedRemainingWork,
    required this.verificationPassRate,
  });

  Map<String, dynamic> toJson() => {
        'completionPercentage': completionPercentage,
        'completedTasks': completedTasks,
        'remainingTasks': remainingTasks,
        'velocity': velocity,
        'estimatedRemainingWorkMs': estimatedRemainingWork.inMilliseconds,
        'verificationPassRate': verificationPassRate,
      };
}

sealed class ProjectEvent {
  final String projectId;
  final DateTime timestamp;

  ProjectEvent({
    required this.projectId,
    required this.timestamp,
  });
}

class ProjectCreated extends ProjectEvent {
  ProjectCreated({required super.projectId, required super.timestamp});
}

class MilestoneStarted extends ProjectEvent {
  final String milestoneId;
  MilestoneStarted({required super.projectId, required super.timestamp, required this.milestoneId});
}

class MilestoneCompleted extends ProjectEvent {
  final String milestoneId;
  MilestoneCompleted({required super.projectId, required super.timestamp, required this.milestoneId});
}

class TaskStarted extends ProjectEvent {
  final String taskId;
  TaskStarted({required super.projectId, required super.timestamp, required this.taskId});
}

class TaskCompleted extends ProjectEvent {
  final String taskId;
  TaskCompleted({required super.projectId, required super.timestamp, required this.taskId});
}

class TaskBlocked extends ProjectEvent {
  final String taskId;
  final String reason;
  TaskBlocked({required super.projectId, required super.timestamp, required this.taskId, required this.reason});
}

class VerificationCompleted extends ProjectEvent {
  final VerificationReport report;
  VerificationCompleted({required super.projectId, required super.timestamp, required this.report});
}

class CheckpointCreated extends ProjectEvent {
  final String checkpointId;
  CheckpointCreated({required super.projectId, required super.timestamp, required this.checkpointId});
}

class RollbackPerformed extends ProjectEvent {
  final String checkpointId;
  RollbackPerformed({required super.projectId, required super.timestamp, required this.checkpointId});
}

class ProjectFinished extends ProjectEvent {
  ProjectFinished({required super.projectId, required super.timestamp});
}
