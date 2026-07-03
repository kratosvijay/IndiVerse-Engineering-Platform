import 'package:test/test.dart';
import 'package:indiverse_developer_platform/core/knowledge/chunkers/line_chunker.dart';
import 'package:indiverse_developer_platform/core/knowledge/document.dart';

void main() {
  group('Chunker Tests', () {
    test('LineChunker correctly partitions lines', () {
      final chunker = const LineChunker(maxLines: 2);
      const doc = Document(
        id: '1',
        uri: '1',
        content: 'line1\nline2\nline3',
        language: 'dart',
        checksum: '123',
        metadata: {},
      );

      final chunks = chunker.chunk(doc);
      expect(chunks.length, equals(2));
      expect(chunks[0].startLine, equals(1));
      expect(chunks[0].endLine, equals(2));
      expect(chunks[1].startLine, equals(3));
      expect(chunks[1].endLine, equals(3));
    });
  });
}
