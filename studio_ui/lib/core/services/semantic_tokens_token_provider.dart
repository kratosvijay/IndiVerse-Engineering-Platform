import 'package:flutter/widgets.dart';
import '../../models/editor_document.dart';
import '../../models/semantic_token.dart';
import '../../models/language_intelligence_models.dart';
import '../../features/editor/highlighting/abstract_highlighter.dart';
import '../../features/editor/controllers/editor_view_controller.dart';
import '../../features/editor/widgets/editor_renderer.dart';
import 'language_intelligence_service.dart';
import 'semantic_token_cache.dart';
import 'semantic_token_decoder.dart';
import 'workbench_providers.dart';

class SemanticTokensTokenProvider implements TokenProvider {
  final SyntaxHighlighter highlighter;
  final LanguageIntelligenceService languageIntel;
  final SemanticTokenCache cache;
  final EditorDocument document;
  final String activeProject;

  EditorViewController? controller;
  bool _isLoading = false;
  CancellationToken? _activeCancelToken;

  SemanticTokensTokenProvider({
    required this.highlighter,
    required this.languageIntel,
    required this.cache,
    required this.document,
    required this.activeProject,
  });

  @override
  InlineSpan tokenizeLine(
    BuildContext context,
    String lineText,
    int lineIndex,
  ) {
    final entry = cache.get(document.path);
    if (entry == null ||
        entry.state != SemanticCacheState.ready ||
        entry.localRevision != document.version.localRevision) {
      _triggerBackgroundUpdate();
      return highlighter.highlight(context, lineText);
    }

    final lineTokens = entry.index.tokensByLine[lineIndex];
    if (lineTokens == null || lineTokens.isEmpty) {
      return highlighter.highlight(context, lineText);
    }

    final List<InlineSpan> spans = [];
    int lastIdx = 0;

    for (final token in lineTokens) {
      final startIdx = token.start.column - 1;
      final endIdx = startIdx + token.length;

      if (startIdx < 0 || startIdx > lineText.length) continue;
      final clampedEndIdx = endIdx.clamp(0, lineText.length);
      if (clampedEndIdx <= startIdx) continue;

      if (startIdx > lastIdx) {
        final rawSubText = lineText.substring(lastIdx, startIdx);
        spans.add(highlighter.highlight(context, rawSubText));
      }

      const theme = EditorTheme.defaultDark;
      final tokenStyle = _getStyleForTokenType(
        token.type,
        token.modifiers,
        theme,
      );
      spans.add(
        TextSpan(
          text: lineText.substring(startIdx, clampedEndIdx),
          style: tokenStyle,
        ),
      );

      lastIdx = clampedEndIdx;
    }

    if (lastIdx < lineText.length) {
      final rawSubText = lineText.substring(lastIdx);
      spans.add(highlighter.highlight(context, rawSubText));
    }

    return TextSpan(children: spans);
  }

  void _triggerBackgroundUpdate() async {
    if (_isLoading) return;
    _isLoading = true;

    cache.put(
      document.path,
      SemanticCacheEntry(
        index: const SemanticTokenIndex(tokensByLine: {}),
        localRevision: document.version.localRevision,
        providerVersion: 1,
        state: SemanticCacheState.loading,
        timestamp: DateTime.now(),
      ),
    );

    _activeCancelToken?.cancel();
    _activeCancelToken = CancellationToken();

    final ctx = LanguageContext(
      document: document,
      position: const Position(line: 1, column: 1),
      workspace: activeProject,
      workspaceRevision: 1,
      token: _activeCancelToken!,
    );

    final res = await languageIntel.getSemanticTokens(ctx);
    _isLoading = false;

    if (_activeCancelToken!.isCancelled) return;

    if (res.success && res.data != null) {
      final decoded = SemanticTokenDecoder.decode(res.data!.data);
      final validated = SemanticTokenValidator.validateAll(
        decoded,
        document.lines,
      );
      final normalized = SemanticTokenNormalizer.normalize(validated);

      cache.put(
        document.path,
        SemanticCacheEntry(
          index: SemanticTokenIndex.build(normalized),
          localRevision: document.version.localRevision,
          providerVersion: 1,
          state: SemanticCacheState.ready,
          timestamp: DateTime.now(),
        ),
      );
    } else {
      cache.put(
        document.path,
        SemanticCacheEntry(
          index: const SemanticTokenIndex(tokensByLine: {}),
          localRevision: document.version.localRevision,
          providerVersion: 1,
          state: res.error?.code == 'TIMEOUT'
              ? SemanticCacheState.timedOut
              : SemanticCacheState.failed,
          timestamp: DateTime.now(),
        ),
      );
    }

    controller?.viewportCache.clear();
    controller?.refresh();
  }

  TextStyle _getStyleForTokenType(
    SemanticTokenType type,
    Set<SemanticTokenModifier> modifiers,
    EditorTheme theme,
  ) {
    TextStyle style = theme.textStyle;
    Color? color;

    switch (type) {
      case SemanticTokenType.namespace:
        color = const Color(0xFF93C5FD);
        break;
      case SemanticTokenType.classType:
      case SemanticTokenType.enumType:
      case SemanticTokenType.mixin:
      case SemanticTokenType.interface:
        color = const Color(0xFF67E8F9);
        style = style.copyWith(fontWeight: FontWeight.bold);
        break;
      case SemanticTokenType.extension:
        color = const Color(0xFF22D3EE);
        break;
      case SemanticTokenType.constructor:
      case SemanticTokenType.method:
      case SemanticTokenType.function:
        color = const Color(0xFFC084FC);
        break;
      case SemanticTokenType.property:
      case SemanticTokenType.field:
        color = const Color(0xFFF472B6);
        break;
      case SemanticTokenType.variable:
      case SemanticTokenType.parameter:
        color = const Color(0xFFFBCFE8);
        break;
      case SemanticTokenType.typeParameter:
        color = const Color(0xFF38BDF8);
        break;
      case SemanticTokenType.annotation:
        color = const Color(0xFFFBBF24);
        break;
      case SemanticTokenType.keyword:
        color = const Color(0xFFF43F5E);
        style = style.copyWith(fontWeight: FontWeight.bold);
        break;
      case SemanticTokenType.operator:
        color = const Color(0xFFA3E635);
        break;
      case SemanticTokenType.number:
        color = const Color(0xFFFB923C);
        break;
      case SemanticTokenType.string:
        color = const Color(0xFF34D399);
        break;
      case SemanticTokenType.comment:
        color = const Color(0xFF6B7280);
        style = style.copyWith(fontStyle: FontStyle.italic);
        break;
      case SemanticTokenType.regexp:
        color = const Color(0xFFFB7185);
        break;
      case SemanticTokenType.label:
        color = const Color(0xFF818CF8);
        break;
    }

    style = style.copyWith(color: color);

    if (modifiers.contains(SemanticTokenModifier.deprecated)) {
      style = style.copyWith(decoration: TextDecoration.lineThrough);
    }

    return style;
  }
}
