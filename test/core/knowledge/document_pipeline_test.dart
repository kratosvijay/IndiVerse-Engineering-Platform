import 'package:test/test.dart';
import 'package:indiverse_developer_platform/core/knowledge/pipelines/document_pipeline.dart';

void main() {
  group('DocumentPipeline Tests', () {
    test('DocumentPipeline loads text source into schema', () async {
      final pipeline = DocumentPipeline();
      final doc = await pipeline.load('test.dart', 'class Test {}');

      expect(doc.uri, equals('test.dart'));
      expect(doc.content, equals('class Test {}'));
    });
  });
}
