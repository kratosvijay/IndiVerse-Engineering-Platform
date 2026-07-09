import 'project_models.dart';
import 'project_repository.dart';
import 'milestone_scheduler.dart';
import 'project_checkpoint_service.dart';
import 'project_progress_engine.dart';

class ProjectExecutionManager {
  final ProjectRepository repository;
  final MilestoneScheduler scheduler = const MilestoneScheduler();
  final ProjectCheckpointService checkpointService = ProjectCheckpointService();
  final ProjectProgressEngine progressEngine = const ProjectProgressEngine();

  ProjectPlan? activePlan;
  final List<ProjectEvent> events = [];

  ProjectExecutionManager({required this.repository});

  // Creates a versioned ProjectPlan and records the created state event
  Future<ProjectPlan> createProject({
    required String id,
    required List<Epic> epics,
  }) async {
    final plan = ProjectPlan(
      id: id,
      version: 1,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      epics: epics,
      state: ProjectState.created,
    );

    activePlan = plan;
    await repository.saveProject(plan);
    _emitEvent(ProjectCreated(projectId: id, timestamp: DateTime.now()));

    return plan;
  }

  // Opens an existing plan from repository
  Future<ProjectPlan?> openProject(String id) async {
    final plan = await repository.loadProject(id);
    if (plan != null) {
      activePlan = plan;
    }
    return plan;
  }

  // Updates project plan state lifecycle transitions
  Future<void> updateProjectState(ProjectState state) async {
    final current = activePlan;
    if (current == null) return;

    final updated = current.copyWith(
      state: state,
      updatedAt: DateTime.now(),
    );

    activePlan = updated;
    await repository.saveProject(updated);

    if (state == ProjectState.completed) {
      _emitEvent(ProjectFinished(projectId: current.id, timestamp: DateTime.now()));
    }
  }

  void _emitEvent(ProjectEvent event) {
    events.add(event);
  }
}

class ProjectExecutionManagerRegistry {
  static ProjectExecutionManager? _active;
  static ProjectExecutionManager? get active => _active;
  static set active(ProjectExecutionManager? manager) => _active = manager;

  static final Map<String, ProjectExecutionManager> _registry = {};
  static void register(String workspaceId, ProjectExecutionManager manager) {
    _registry[workspaceId] = manager;
    _active ??= manager;
  }
  static ProjectExecutionManager? get(String workspaceId) => _registry[workspaceId];
  static void clear() {
    _registry.clear();
    _active = null;
  }
}
