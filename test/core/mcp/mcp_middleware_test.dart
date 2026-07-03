import 'package:test/test.dart';
import 'package:indiverse_developer_platform/core/mcp/registry/cancellation_registry.dart';

void main() {
  group('MCP Middleware & Cancellation Tests', () {
    test('Verify cancellation tracking', () {
      final registry = CancellationRegistry();
      expect(registry.isCancelled('req-1'), isFalse);
      registry.cancel('req-1');
      expect(registry.isCancelled('req-1'), isTrue);
    });
  });
}
