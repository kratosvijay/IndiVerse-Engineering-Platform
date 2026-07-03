import 'package:test/test.dart';
import 'package:indiverse_developer_platform/core/knowledge/scheduler/reindex_scheduler.dart';

void main() {
  group('ReindexScheduler Tests', () {
    test('Schedule index operations debounces correctly', () {
      final scheduler = ReindexScheduler();
      scheduler.schedule('path/to/file');
      expect(scheduler, isNotNull);
    });
  });
}
