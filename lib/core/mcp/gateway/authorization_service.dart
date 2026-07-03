import '../models/permission.dart';

class AuthorizationService {
  Future<bool> authorize(
    List<Permission> userPermissions,
    List<Permission> requiredPermissions,
  ) async {
    return requiredPermissions.every((p) => userPermissions.contains(p));
  }
}
