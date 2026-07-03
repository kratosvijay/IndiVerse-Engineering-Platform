import '../manifest.dart';

class RuntimeCompatibilityValidator {
  final String currentRuntimeVersion;

  RuntimeCompatibilityValidator({this.currentRuntimeVersion = "0.3.0"});

  bool check(IntegrationManifest manifest) {
    final min = manifest.minRuntimeVersion;
    final max = manifest.maxRuntimeVersion;

    return currentRuntimeVersion.compareTo(min) >= 0 &&
        currentRuntimeVersion.compareTo(max) <= 0;
  }
}
