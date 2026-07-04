import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/language_intelligence_models.dart';
import '../../models/editor_document.dart';
import 'language_intelligence_providers.dart';
import 'workbench_providers.dart';

class DefaultHoverProvider implements HoverProvider {
  final int port;

  @override
  final String id = 'default-hover';
  @override
  final String language = '*';
  @override
  final int version = 1;
  @override
  final int priority = 1;
  @override
  ProviderState state = ProviderState.ready;
  @override
  final ProviderMetrics metrics = ProviderMetrics();

  DefaultHoverProvider({required this.port});

  @override
  Future<void> initialize() async {}
  @override
  Future<void> start() async {}
  @override
  Future<void> stop() async {}
  @override
  Future<void> dispose() async {}

  @override
  Future<OperationResult<Hover>> provideHover(
    ProviderExecutionContext context,
  ) async {
    final doc = context.request.context.document;
    final pos = context.request.context.position;
    final word = _getWordAt(doc, pos);

    if (word == null || word.isEmpty) {
      return const OperationResult.fail(
        WorkbenchError(code: 'NO_SYMBOL', message: 'No symbol under cursor.'),
      );
    }

    try {
      final res = await http.get(
        Uri.parse('http://localhost:$port/api/v1/code/definition?name=$word'),
      );
      if (res.statusCode == 200) {
        final envelope = jsonDecode(res.body);
        if (envelope["success"] == true) {
          final data = envelope["data"];
          final path = data["path"] ?? '';
          final line = data["line"] ?? 1;

          final docString = '''
**Symbol**: `$word`
**Defined at**: `$path` (Line $line)

Documentation source: *Local symbol index*
''';
          return OperationResult.ok(Hover(contents: docString));
        }
      }
      final fallbackDoc = '''
**Symbol**: `$word`

*No documentation definition found.*
''';
      return OperationResult.ok(Hover(contents: fallbackDoc));
    } catch (e) {
      return OperationResult.fail(
        WorkbenchError(code: 'INTERNAL_ERROR', message: e.toString()),
      );
    }
  }

  String? _getWordAt(EditorDocument doc, Position pos) {
    if (pos.line < 1 || pos.line > doc.lines.length) return null;
    final lineStr = doc.lines[pos.line - 1];
    if (lineStr.isEmpty || pos.column > lineStr.length) return null;

    int start = pos.column - 1;
    if (start >= lineStr.length) start = lineStr.length - 1;
    if (start < 0) return null;

    final isWordChar = (String char) => RegExp(r'[a-zA-Z0-9_]').hasMatch(char);
    if (!isWordChar(lineStr[start])) return null;

    while (start > 0 && isWordChar(lineStr[start - 1])) {
      start--;
    }
    int end = pos.column - 1;
    while (end < lineStr.length && isWordChar(lineStr[end])) {
      end++;
    }
    return lineStr.substring(start, end);
  }
}
