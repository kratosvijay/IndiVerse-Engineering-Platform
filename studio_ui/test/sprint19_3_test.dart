import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/models/editor_document.dart';
import 'package:studio_ui/models/folding_region.dart';
import 'package:studio_ui/features/editor/controllers/folding_provider.dart';
import 'package:studio_ui/core/services/navigation_history.dart';

void main() {
  group('Folding Engine Tests', () {
    test('Bracket folding regions nested parsing', () {
      final doc = EditorDocument(
        id: 'test.json',
        path: 'test.json',
        name: 'test.json',
        content:
            '{\n  "name": "IndiVerse",\n  "array": [\n    1,\n    2\n  ]\n}',
        language: 'json',
        encoding: 'utf8',
        lastModified: '',
        readOnly: false,
      );

      final provider = JsonFoldingProvider();
      final regions = provider.build(doc);

      expect(regions.length, 1);
      final root = regions.first;
      expect(root.startLine, 1);
      expect(root.endLine, 7);
      expect(root.children.length, 1);

      final child = root.children.first;
      expect(child.startLine, 3);
      expect(child.endLine, 6);
    });

    test('Markdown header folding parsing', () {
      final doc = EditorDocument(
        id: 'test.md',
        path: 'test.md',
        name: 'test.md',
        content:
            '# Header 1\nSome text\n## Header 2\nMore text\n# Header 3\nLast line text',
        language: 'markdown',
        encoding: 'utf8',
        lastModified: '',
        readOnly: false,
      );

      final provider = MarkdownFoldingProvider();
      final regions = provider.build(doc);

      expect(regions.length, 2);
      expect(regions[0].startLine, 1);
      expect(regions[0].endLine, 4);
      expect(regions[0].children.length, 1);

      expect(regions[0].children[0].startLine, 3);
      expect(regions[0].children[0].endLine, 4);

      expect(regions[1].startLine, 5);
      expect(regions[1].endLine, 6);
    });
  });

  group('NavigationHistory Tests', () {
    test('Semantic triggers & bounded capacity limits', () {
      final history = NavigationHistory();

      history.record('file1.dart', 10, 1);
      history.record('file2.dart', 20, 1);
      history.record('file3.dart', 30, 1);

      expect(history.entries.length, 3);
      expect(history.currentIndex, 2);

      final loc1 = history.goBack();
      expect(loc1?.path, 'file2.dart');
      expect(loc1?.line, 20);

      final loc2 = history.goBack();
      expect(loc2?.path, 'file1.dart');
      expect(loc2?.line, 10);

      expect(history.goBack(), null);

      final loc3 = history.goForward();
      expect(loc3?.path, 'file2.dart');

      for (int i = 0; i < 250; i++) {
        history.record('file_$i.dart', 100, 1);
      }
      expect(history.entries.length, 200);
    });
  });
}
