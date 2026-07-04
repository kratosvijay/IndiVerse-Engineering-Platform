import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/models/editor_document.dart';
import 'package:studio_ui/models/semantic_token.dart';
import 'package:studio_ui/core/services/semantic_token_decoder.dart';
import 'package:studio_ui/core/services/semantic_token_cache.dart';
import 'package:studio_ui/core/services/workbench_providers.dart';
import 'package:studio_ui/core/state/studio_state.dart';
import 'package:studio_ui/features/editor/widgets/editor_widget.dart';
import 'package:studio_ui/models/ids.dart';
import 'package:studio_ui/models/language_intelligence_models.dart';
import 'package:studio_ui/core/services/language_intelligence_providers.dart';

class MockSemanticTokensProvider implements SemanticTokensProvider {
  @override
  final String id = 'mock-sem';
  @override
  final String language = 'dart';
  @override
  final int version = 1;
  @override
  final int priority = 100;
  @override
  ProviderState state = ProviderState.ready;
  @override
  final ProviderMetrics metrics = ProviderMetrics();

  final List<int> rawTokensData;
  Duration delay = Duration.zero;

  MockSemanticTokensProvider({required this.rawTokensData});

  @override
  Future<void> initialize() async {}
  @override
  Future<void> start() async {}
  @override
  Future<void> stop() async {}
  @override
  Future<void> dispose() async {}

  @override
  Future<OperationResult<SemanticTokensResult>> provideSemanticTokens(
    ProviderExecutionContext context,
  ) async {
    if (delay > Duration.zero) {
      await Future.delayed(delay);
    }
    if (context.request.context.token.isCancelled) {
      return const OperationResult.fail(
        WorkbenchError(code: 'CANCELLED', message: 'Cancelled.'),
      );
    }
    return OperationResult.ok(SemanticTokensResult(data: rawTokensData));
  }
}

void main() {
  group('Semantic Token Decoder & Validator Tests', () {
    test('Decoder absolute coordinate delta math conversions', () {
      // Relative LSP integers: [deltaLine, deltaStartChar, length, tokenTypeIndex, modifiers]
      // Token 1: line 1, column 5, length 4, class (1), static modifier (8)
      // Token 2: same line (delta 0), start relative by 6 (col 5 + 6 = 11), length 6, method (7), async modifier (32)
      // Token 3: line 2 (delta 1), start relative to col 1 (deltaStart 2 => col 3), length 3, keyword (17), deprecated (16)
      final List<int> rawData = [
        0,
        4,
        4,
        1,
        8, // Token 1: Line 1, Col 5 (0+1=1 line, 0+4=4 offset => col 5)
        0, 6, 6, 7, 32, // Token 2: Line 1, Col 11 (col 5 + 6 = 11)
        1,
        2,
        3,
        17,
        16, // Token 3: Line 2, Col 3 (1+1=2 line, 2 offset => col 3)
      ];

      final decoded = SemanticTokenDecoder.decode(rawData);
      expect(decoded.length, 3);

      expect(decoded[0].start.line, 1);
      expect(decoded[0].start.column, 5);
      expect(decoded[0].length, 4);
      expect(decoded[0].type, SemanticTokenType.classType);
      expect(
        decoded[0].modifiers.contains(SemanticTokenModifier.staticToken),
        true,
      );

      expect(decoded[1].start.line, 1);
      expect(decoded[1].start.column, 11);
      expect(decoded[1].length, 6);
      expect(decoded[1].type, SemanticTokenType.method);
      expect(
        decoded[1].modifiers.contains(SemanticTokenModifier.abstractToken),
        true,
      );

      expect(decoded[2].start.line, 2);
      expect(decoded[2].start.column, 3);
      expect(decoded[2].length, 3);
      expect(decoded[2].type, SemanticTokenType.number);
      expect(
        decoded[2].modifiers.contains(SemanticTokenModifier.deprecated),
        true,
      );
    });

    test('Validator checks boundaries and validates line lengths', () {
      final List<String> docLines = ['class Test { }', 'var x = 1;'];

      final tokenValid = SemanticToken(
        start: const Position(line: 1, column: 1),
        length: 5,
        type: SemanticTokenType.keyword,
        modifiers: const {},
      );

      final tokenInvalidLine = SemanticToken(
        start: const Position(line: 3, column: 1),
        length: 5,
        type: SemanticTokenType.keyword,
        modifiers: const {},
      );

      final tokenInvalidCol = SemanticToken(
        start: const Position(line: 1, column: 20),
        length: 5,
        type: SemanticTokenType.keyword,
        modifiers: const {},
      );

      expect(
        SemanticTokenValidator.isValid(tokenValid, docLines.length, docLines),
        true,
      );
      expect(
        SemanticTokenValidator.isValid(
          tokenInvalidLine,
          docLines.length,
          docLines,
        ),
        false,
      );
      expect(
        SemanticTokenValidator.isValid(
          tokenInvalidCol,
          docLines.length,
          docLines,
        ),
        false,
      );
    });

    test('Normalizer deduplicates and sorts tokens correctly', () {
      // Setup unsorted tokens
      final t1 = SemanticToken(
        start: const Position(line: 2, column: 1),
        length: 3,
        type: SemanticTokenType.keyword,
        modifiers: const {},
      );
      final t2 = SemanticToken(
        start: const Position(line: 1, column: 10),
        length: 4,
        type: SemanticTokenType.method,
        modifiers: const {},
      );
      final t3 = SemanticToken(
        start: const Position(line: 1, column: 5),
        length: 5,
        type: SemanticTokenType.classType,
        modifiers: const {},
      );
      // Exact duplicate of t3
      final t4 = SemanticToken(
        start: const Position(line: 1, column: 5),
        length: 5,
        type: SemanticTokenType.classType,
        modifiers: const {SemanticTokenModifier.deprecated},
      );

      final normalized = SemanticTokenNormalizer.normalize([t1, t2, t3, t4]);
      expect(normalized.length, 3);
      // Sorted order check
      expect(normalized[0].start.line, 1);
      expect(normalized[0].start.column, 5);
      // Duplicate merged modifiers check
      expect(
        normalized[0].modifiers.contains(SemanticTokenModifier.deprecated),
        true,
      );

      expect(normalized[1].start.line, 1);
      expect(normalized[1].start.column, 10);

      expect(normalized[2].start.line, 2);
      expect(normalized[2].start.column, 1);
    });
  });

  group('Semantic Token Cache Tests', () {
    test('Cache state lifecycle & incremental merge updates', () {
      final cache = SemanticTokenCache();
      final path = 'main.dart';

      // Verify missing cache state
      expect(cache.get(path), null);

      // Populate Cache
      final t1 = SemanticToken(
        start: const Position(line: 1, column: 1),
        length: 5,
        type: SemanticTokenType.keyword,
        modifiers: const {},
      );
      final t2 = SemanticToken(
        start: const Position(line: 2, column: 2),
        length: 4,
        type: SemanticTokenType.variable,
        modifiers: const {},
      );

      cache.put(
        path,
        SemanticCacheEntry(
          index: SemanticTokenIndex.build([t1, t2]),
          localRevision: 1,
          providerVersion: 1,
          state: SemanticCacheState.ready,
          timestamp: DateTime.now(),
        ),
      );

      final entry = cache.get(path);
      expect(entry != null, true);
      expect(entry!.state, SemanticCacheState.ready);
      expect(entry.index.tokensByLine[1]!.first, t1);
      expect(entry.index.tokensByLine[2]!.first, t2);

      // Perform Incremental Merge on line 2
      final t3 = SemanticToken(
        start: const Position(line: 2, column: 5),
        length: 3,
        type: SemanticTokenType.number,
        modifiers: const {},
      );

      cache.merge(path, [t3], 2, 2, 1, 1);

      final mergedEntry = cache.get(path);
      expect(mergedEntry != null, true);
      // Line 1 should be untouched
      expect(mergedEntry!.index.tokensByLine[1]!.first, t1);
      // Line 2 should only have new token t3, old t2 discarded
      expect(mergedEntry.index.tokensByLine[2]!.first, t3);
      expect(mergedEntry.index.tokensByLine[2]!.contains(t2), false);
    });
  });

  group('Editor Integration & Presentation Tests', () {
    testWidgets('Editor renders semantically highlited tokens in background', (
      WidgetTester tester,
    ) async {
      final state = StudioState();
      state.connect(18080);

      // Relative LSP integers: [deltaLine, deltaStartChar, length, tokenTypeIndex, modifiers]
      // void main() { }
      // void: keyword (17), main: method (7)
      // col 1: 'void' starts at col 1 (delta 0, deltaStart 0, length 4, keyword=17, modifier=0)
      // col 6: 'main' starts at col 6 (delta 0, deltaStart 5, length 4, method=7, modifier=0)
      final List<int> testTokens = [0, 0, 4, 17, 0, 0, 5, 4, 7, 0];

      await state.languageRegistry.registerSemanticTokensProvider(
        'dart',
        MockSemanticTokensProvider(rawTokensData: testTokens),
      );

      final doc = EditorDocument(
        id: 'main.dart',
        path: 'main.dart',
        name: 'main.dart',
        content: 'void main() { }',
        language: 'dart',
        encoding: 'utf8',
        lastModified: '',
        readOnly: false,
      );
      state.editor.open(doc);
      state.documentService.cacheDocument(DocumentId(doc.path), doc);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 400,
              width: 1000,
              child: EditorWidget(state: state),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Trigger background update and pump frame updates
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();

      // Verify the cache has transitioned to ready and index has the lines populated
      final cacheEntry = state.languageRegistry.semanticCache.get(doc.path);
      expect(cacheEntry != null, true);
      expect(cacheEntry!.state, SemanticCacheState.ready);
      expect(cacheEntry.index.tokensByLine[1]!.length, 2);

      // Verify the CustomPaint renderer renders
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });
}
