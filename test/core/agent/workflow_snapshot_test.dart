import 'package:test/test.dart';
import 'package:indiverse_developer_platform/core/agent/workflow/workflow_snapshot.dart';

void main() {
  group('WorkflowSnapshot Tests', () {
    test('Construct workflow snapshots', () {
      const snapshot = WorkflowSnapshot('wf-1', 'active');
      expect(snapshot.id, equals('wf-1'));
      expect(snapshot.state, equals('active'));
    });
  });
}
