import '../manifest.dart';

class PlatformCompatibilityValidator {
  final String currentPlatform;

  PlatformCompatibilityValidator({this.currentPlatform = "macos"});

  bool check(IntegrationManifest manifest) {
    return manifest.supportedPlatforms.contains(currentPlatform);
  }
}
