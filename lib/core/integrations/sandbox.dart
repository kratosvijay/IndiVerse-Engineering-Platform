import 'manifest.dart';

class PluginSandbox {
  final Map<String, dynamic> globalPermissions;

  PluginSandbox(
      {this.globalPermissions = const {
        "filesystem": true,
        "terminal": true,
        "git": true,
        "network": true,
        "clipboard": true,
        "process": true,
        "environment": true,
      }});

  bool checkPermission(IntegrationManifest manifest, String permission) {
    final pluginPerms = manifest.permissions;
    if (pluginPerms.contains(permission)) {
      return globalPermissions[permission] == true;
    }
    return false;
  }
}
