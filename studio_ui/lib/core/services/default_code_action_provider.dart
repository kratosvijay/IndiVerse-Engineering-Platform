import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/language_intelligence_models.dart';
import 'language_intelligence_providers.dart';
import 'workbench_providers.dart';

class DefaultCodeActionProvider implements CodeActionProvider {
  final int port;

  @override
  final String id = 'default-codeactions';
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

  DefaultCodeActionProvider({required this.port});

  @override
  Future<void> initialize() async {}
  @override
  Future<void> start() async {}
  @override
  Future<void> stop() async {}
  @override
  Future<void> dispose() async {}

  @override
  Future<OperationResult<List<CodeAction>>> provideCodeActions(
    ProviderExecutionContext context,
  ) async {
    final doc = context.request.context.document;
    final pos = context.request.context.position;
    final revision = doc.version.localRevision;
    final token = context.request.context.token;

    final selStart = doc.selection?.start ?? pos;
    final selEnd = doc.selection?.end ?? pos;

    try {
      final client = http.Client();
      final url = Uri.parse(
        'http://localhost:$port/api/v1/code/codeActions'
        '?path=${Uri.encodeComponent(doc.path)}'
        '&line=${pos.line}'
        '&column=${pos.column}'
        '&revision=$revision'
        '&selectionStartLine=${selStart.line}'
        '&selectionStartColumn=${selStart.column}'
        '&selectionEndLine=${selEnd.line}'
        '&selectionEndColumn=${selEnd.column}',
      );

      final responseFuture = client.get(url);

      final http.Response res = await responseFuture.timeout(
        const Duration(seconds: 3),
      );

      if (token.isCancelled) {
        return const OperationResult.fail(
          WorkbenchError(code: 'CANCELLED', message: 'Request was cancelled.'),
        );
      }

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body) as Map<String, dynamic>;
        if (decoded['success'] == true) {
          final data = decoded['data'] as Map<String, dynamic>;
          final actionsList = data['actions'] as List? ?? [];
          final actions = actionsList
              .map((a) => CodeAction.fromJson(a as Map<String, dynamic>))
              .toList();
          return OperationResult.ok(actions);
        } else {
          final errors = decoded['errors'] as List? ?? [];
          final msg = errors.isNotEmpty
              ? errors.first.toString()
              : 'Unknown error';
          return OperationResult.fail(
            WorkbenchError(code: 'SERVER_ERROR', message: msg),
          );
        }
      } else {
        return OperationResult.fail(
          WorkbenchError(
            code: 'HTTP_ERROR',
            message: 'Server returned status code ${res.statusCode}',
          ),
        );
      }
    } catch (e) {
      return OperationResult.fail(
        WorkbenchError(code: 'CONNECTION_FAILED', message: e.toString()),
      );
    }
  }
}
