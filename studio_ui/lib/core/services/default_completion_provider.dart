import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/language_intelligence_models.dart';
import 'language_intelligence_providers.dart';
import 'workbench_providers.dart';

class DefaultCompletionProvider implements CompletionItemProvider {
  final int port;

  @override
  final String id = 'default-completion';
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

  DefaultCompletionProvider({required this.port});

  @override
  Future<void> initialize() async {}
  @override
  Future<void> start() async {}
  @override
  Future<void> stop() async {}
  @override
  Future<void> dispose() async {}

  @override
  Future<OperationResult<List<CompletionItem>>> provideCompletions(
    ProviderExecutionContext context,
  ) async {
    final doc = context.request.context.document;
    final pos = context.request.context.position;

    // Extract typed prefix before the cursor position
    String prefix = '';
    try {
      final lineContent = doc.lines[pos.line - 1];
      final col = pos.column - 1;
      if (col > 0 && col <= lineContent.length) {
        int start = col - 1;
        while (start >= 0) {
          final c = lineContent[start];
          if (RegExp(r'[a-zA-Z0-9_]').hasMatch(c)) {
            start--;
          } else {
            break;
          }
        }
        prefix = lineContent.substring(start + 1, col);
      }
    } catch (_) {}

    try {
      final res = await http.get(
        Uri.parse(
          'http://localhost:$port/api/v1/code/completions?path=${Uri.encodeComponent(doc.path)}&line=${pos.line}&column=${pos.column}&prefix=${Uri.encodeComponent(prefix)}',
        ),
      );
      if (res.statusCode == 200) {
        final envelope = jsonDecode(res.body);
        if (envelope["success"] == true) {
          final listData = envelope["data"]["items"] as List? ?? [];
          final list = listData
              .map((x) => CompletionItem.fromJson(x as Map<String, dynamic>))
              .toList();
          return OperationResult.ok(list);
        }
      }
      return const OperationResult.ok([]);
    } catch (e) {
      return OperationResult.fail(
        WorkbenchError(code: 'INTERNAL_ERROR', message: e.toString()),
      );
    }
  }
}
