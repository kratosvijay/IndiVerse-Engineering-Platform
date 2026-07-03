import 'permission.dart';

class SessionContext {
  final String sessionId;
  final String protocolVersion;
  final List<Permission> permissions;

  const SessionContext({
    required this.sessionId,
    required this.protocolVersion,
    required this.permissions,
  });
}
