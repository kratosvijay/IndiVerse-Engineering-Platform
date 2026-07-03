import 'package:test/test.dart';
import 'package:indiverse_developer_platform/core/mcp/server/session.dart';

void main() {
  group('MCP Session Tests', () {
    test('Verify session construction', () {
      const session = McpSession('session-1', '2025-03');
      expect(session.sessionId, equals('session-1'));
      expect(session.negotiatedVersion, equals('2025-03'));
    });
  });
}
