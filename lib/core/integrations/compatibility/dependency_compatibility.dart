import '../manifest.dart';

class DependencyCompatibilityValidator {
  final List<String> installedBinaries;

  DependencyCompatibilityValidator(
      {this.installedBinaries = const ["python", "git", "docker"]});

  bool check(IntegrationManifest manifest) {
    for (final dep in manifest.dependencies) {
      if (!installedBinaries.contains(dep.toLowerCase())) {
        return false;
      }
    }
    return true;
  }
}
