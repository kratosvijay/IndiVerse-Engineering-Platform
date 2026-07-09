import 'project_models.dart';

abstract interface class ProjectRepository {
  Future<void> saveProject(ProjectPlan plan);
  Future<ProjectPlan?> loadProject(String projectId);
  Future<List<String>> listProjects();
}

class JsonProjectRepository implements ProjectRepository {
  final Map<String, ProjectPlan> _storage = {};

  @override
  Future<void> saveProject(ProjectPlan plan) async {
    _storage[plan.id] = plan;
  }

  @override
  Future<ProjectPlan?> loadProject(String projectId) async {
    return _storage[projectId];
  }

  @override
  Future<List<String>> listProjects() async {
    return _storage.keys.toList();
  }
}
