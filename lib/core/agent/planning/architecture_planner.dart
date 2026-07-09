import '../../workspace/graph/workspace_snapshot.dart';
import 'planning_models.dart';

class ArchitecturePlanner {
  // Plan architectural details mapping impacted files and services using snapshot intelligence
  ArchitectureImpact planImpact(
      GoalAnalysis goalAnalysis, WorkspaceSnapshot snapshot) {
    final files = <String>[];
    final services = <String>[];
    final routes = <String>[];
    final providers = <String>[];
    final tests = <String>[];
    final apis = <String>[];
    final database = <String>[];

    // Read snapshot structures to match impacted items
    for (final sym in snapshot.symbols) {
      final name = sym.name.toLowerCase();
      if (name.contains('auth') || name.contains('service')) {
        services.add(sym.id);
        files.add(sym.filePath);
      }
      if (name.contains('route') || name.contains('controller')) {
        routes.add(sym.id);
      }
      if (name.contains('provider')) {
        providers.add(sym.id);
      }
    }

    if (goalAnalysis.goal.toLowerCase().contains('database') ||
        goalAnalysis.goal.toLowerCase().contains('db')) {
      database.add('schema-migration');
    }

    // Heuristically append boilerplate files if none matched
    if (files.isEmpty) {
      files.add('lib/main.dart');
    }
    tests.add('test/core/agent/agent_collaboration_test.dart');

    return ArchitectureImpact(
      files: files.toSet().toList(),
      services: services,
      routes: routes,
      providers: providers,
      tests: tests,
      apis: apis,
      database: database,
    );
  }
}
